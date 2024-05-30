# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2024 Rother OSS GmbH, https://otobo.de/
# --
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
# --

use v5.24;
use strict;
use warnings;
use utf8;

# core modules

# CPAN modules
use Test2::V0;

# OTOBO modules
use Kernel::System::UnitTest::RegisterDriver;    # Set up $Kernel::OM
use Kernel::GenericInterface::Debugger ();
use Kernel::System::UnitTest::Selenium;

my $Selenium = Kernel::System::UnitTest::Selenium->new( LogExecuteCommandActive => 1 );

$Selenium->RunTest(
    sub {

        my $Helper           = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
        my $WebserviceObject = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice');

        # Do not check RichText.
        $Helper->ConfigSettingChange(
            Valid => 1,
            Key   => 'Frontend::RichText',
            Value => 0,
        );

        my $RandomID = $Helper->GetRandomID();

        # Create test web service.
        my $WebserviceID = $WebserviceObject->WebserviceAdd(
            Config => {
                Debugger => {
                    DebugThreshold => 'debug',
                    TestMode       => 1,
                },
                Provider => {
                    Transport => {
                        Type => '',
                    },
                },
            },
            Name    => "Selenium $RandomID web service",
            ValidID => 1,
            UserID  => 1,
        );

        ok(
            $WebserviceID,
            "Web service ID $WebserviceID is created"
        );

        # Create debugger object.
        my $DebuggerObject = Kernel::GenericInterface::Debugger->new(
            DebuggerConfig => {
                DebugThreshold => 'debug',
                TestMode       => 0,
            },
            WebserviceID      => $WebserviceID,
            CommunicationType => 'Provider',
        );

        is(
            ref $DebuggerObject,
            'Kernel::GenericInterface::Debugger',
            'DebuggerObject instantiate correctly',
        );

        # Create test user and login.
        my $TestUserLogin = $Helper->TestUserCreate(
            Groups => ['admin'],
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        my $ScriptAlias = $Kernel::OM->Get('Kernel::Config')->Get('ScriptAlias');

        # Navigate to AdminGenericInterfaceWebservice screen.
        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AdminGenericInterfaceWebservice");

        # Click on created web service.
        $Selenium->find_element("//a[contains(\@href, 'WebserviceID=$WebserviceID')]")->VerifiedClick();

        # Check breadcrumb on Overview screen.
        ok(
            $Selenium->find_element( '.BreadCrumb', 'css' ),
            "Breadcrumb is found on Overview screen.",
        );

        # Select 'Ticket::TicketCreate' as option.
        $Selenium->InputFieldValueSet(
            Element => '#OperationList',
            Value   => 'Ticket::TicketCreate',
        );

        # Wait for page to load if necessary.
        $Selenium->WaitFor( JavaScript => 'return typeof($) === "function" && $("#Operation").length' );

        # Create web service operation.
        $Selenium->find_element( "#Operation", 'css' )->send_keys('SeleniumOperation');

        # Select XSLT mapping for inbound data.
        $Selenium->InputFieldValueSet(
            Element => '#MappingInbound',
            Value   => 'XSLT',
        );

        # Set include ticket data to Yes.
        $Selenium->InputFieldValueSet(
            Element => '#IncludeTicketData',
            Value   => 1,
        );

        # Submit operation.
        $Selenium->find_element( "#Submit", 'css' )->VerifiedClick();

        # Verify ticket data option.
        is(
            $Selenium->find_element( '#IncludeTicketData', 'css' )->get_value(),
            '1',
            'Include ticket data set to Yes'
        );

        # Click to configure inbound mapping XSLT.
        $Selenium->find_element("//button[\@id='MappingInboundConfigureButton']")->VerifiedClick();

        # Check screen.
        $Selenium->find_element_by_css_ok('#Template');

        # Check for breadcrumb on screen.
        my $Count = 1;
        for my $Breadcrumb (
            "Web Service Management",
            "Selenium $RandomID web service",
            "Operation: SeleniumOperation",
            "XSLT Mapping for Incoming Data"
            )
        {
            is(
                $Selenium->execute_script("return \$('.BreadCrumb li:eq($Count)').text().trim()"),
                $Breadcrumb,
                "Breadcrumb text '$Breadcrumb' is found on screen"
            );

            $Count++;
        }

        # Submit empty form and check client side validation.
        $Selenium->find_element( "#Submit", 'css' )->click;
        $Selenium->WaitFor(
            JavaScript => "return typeof(\$) === 'function' && \$('#Template.Error').length"
        );

        is(
            $Selenium->execute_script(
                q{return $('#Template').hasClass('Error')}
            ),
            '1',
            'Client side validation correctly detected missing input value for #Template',
        );

        # Input invalid XSLT data.
        # first find the editable element (throws exception when it can't found)
        #$Selenium->find_element( "#Template", 'css' )->send_keys($RandomID);
        my $TemplateElement = $Selenium->find_element(
            q{//textarea[@id="Template"]},
            'xpath'
        );
        is(
            $TemplateElement->execute_script(
                q{return arguments[0].classList.contains('CodeMirrorEditor')},
            ),
            '1',
            'The textarea has the class CodeMirrorEditor',
        );

        # Get the CodeMirror instance and set the content.
        # Note that the method 'data' is jQuery specific, hence the $(...)
        $TemplateElement->execute_script(
            q{$(arguments[0]).data('CodeMirrorInstance').setValue(arguments[1]);},
            $RandomID
        );

        # Submit invalid XSLT.
        $Selenium->find_element( "#Submit", 'css' )->click;
        $Selenium->WaitFor(
            JavaScript => 'return $(".Dialog.Modal #DialogButton1").length'
        );

        # Click to confirm error and verify it.
        $Selenium->find_element( "#DialogButton1", 'css' )->click;
        $Selenium->WaitFor(
            JavaScript =>
                'return !$(".Dialog.Modal").length'
        );

        ok(
            $Selenium->find_element( "#Accessibility_AlertMessage", 'css' ),
            "Error for invalid XSLT data is found"
        );

        # Input correct XSLT data.
        my $XSLTData = '<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" encoding="utf-8" indent="yes"/>
<xsl:template match="/RootElement">
<NewRootElement><NewKey>NewValue</NewKey></NewRootElement>
</xsl:template>
</xsl:stylesheet>';

        my $TemplateElement2 = $Selenium->find_element(
            q{//textarea[@id="Template"]},
            'xpath'
        );
        $TemplateElement2->execute_script(
            q{$(arguments[0]).data('CodeMirrorInstance').setValue(arguments[1]);},
            $XSLTData
        );

        # Add invalid pre XSLT regex.
        $Selenium->find_element( '#WidgetRegExFiltersPre', 'css' )->click;
        $Selenium->WaitFor(
            JavaScript => "return \$('#WidgetRegExFiltersPre.Expanded').length"
        );
        $Selenium->find_element( "#PreAddValue", 'css' )->click;
        $Selenium->WaitFor(
            JavaScript => "return \$('.PreValueInsert .ValueRow #PreKey_1').length"
        );

        # Submit invalid pre XSLT regex.
        $Selenium->find_element( "#Submit", 'css' )->click;
        $Selenium->WaitFor(
            JavaScript => "return typeof(\$) === 'function' && \$('#PreKey_1.Error').length"
        );

        # Check client side validation.
        is(
            $Selenium->execute_script(
                q{return $('#PreKey_1').hasClass('Error')},
            ),
            '1',
            'Client side validation correctly detected missing input value for #PreKey_1',
        );

        # Add correct pre XSLT regex.
        $Selenium->find_element( "#PreKey_1",   'css' )->send_keys( $RandomID . 'PreKey_1' );
        $Selenium->find_element( "#PreValue_1", 'css' )->send_keys( $RandomID . 'PreValue_1' );

        $Selenium->find_element( "#PreAddValue", 'css' )->click;
        $Selenium->WaitFor(
            JavaScript => "return \$('.PreValueInsert .ValueRow #PreKey_2').length"
        );

        $Selenium->find_element( "#PreAddValue", 'css' )->click;
        $Selenium->WaitFor(
            JavaScript => "return \$('.PreValueInsert .ValueRow #PreKey_3').length"
        );

        $Selenium->find_element( "#PreKey_2",   'css' )->send_keys( $RandomID . 'PreKey_2' );
        $Selenium->find_element( "#PreKey_3",   'css' )->send_keys( $RandomID . 'PreKey_3' );
        $Selenium->find_element( "#PreValue_3", 'css' )->send_keys( $RandomID . 'PreValue_3' );

        # Add post XSLT regex.
        $Selenium->find_element( '#WidgetRegExFiltersPost', 'css' )->click;
        $Selenium->WaitFor(
            JavaScript => "return \$('#WidgetRegExFiltersPost.Expanded').length"
        );

        $Selenium->find_element( '#PostAddValue', 'css' )->click;
        $Selenium->WaitFor(
            JavaScript => "return \$('.PostValueInsert .ValueRow #PostKey_1').length"
        );

        my $PostKey   = $RandomID . 'PostKey_1';
        my $PostValue = $RandomID . 'PostValue_1';
        $Selenium->execute_script("\$('#PostKey_1').val('$PostKey');");
        $Selenium->execute_script("\$('#PostValue_1').val('$PostValue');");

        # Add data include configuration.
        $Selenium->InputFieldValueSet(
            Element => '#DataInclude',
            Value   => 'ProviderRequestInput',
        );

        # Click on 'Save and finish' test JS redirection.
        $Selenium->find_element( "#Submit", 'css' )->VerifiedClick();

        ok(
            index( $Selenium->get_current_url(), 'AdminGenericInterfaceOperationDefault' ) > -1,
            'JS redirection is successful to AdminGenericInterfaceOperationDefault screen'
        );

        $Selenium->WaitFor(
            JavaScript => 'return typeof($) === "function" && $("#MappingInboundConfigureButton").length'
        );

        # Click on configure inbound mapping XSLT again.
        $Selenium->find_element("//button[\@id='MappingInboundConfigureButton']")->VerifiedClick();

        # Verify saved data.
        is(
            $Selenium->find_element( "#Template", 'css' )->get_value(),
            $XSLTData,
            "XSLT data is successfully saved"
        );
        is(
            $Selenium->find_element( '#DataInclude', 'css' )->get_value(),
            'ProviderRequestInput',
            "#DataInclude stored value",
        );

        # Verify saved regex data.
        is(
            $Selenium->find_element( "#PreKey_1", 'css' )->get_value(),
            $RandomID . 'PreKey_1',
            "Pre RegEx data is successfully saved"
        );

        is(
            $Selenium->find_element( "#PreValue_1", 'css' )->get_value(),
            $RandomID . 'PreValue_1',
            "Pre RegEx data is successfully saved"
        );

        is(
            $Selenium->find_element( "#PreKey_2", 'css' )->get_value(),
            $RandomID . 'PreKey_2',
            "Pre RegEx data is successfully saved"
        );

        is(
            $Selenium->find_element( "#PreValue_2", 'css' )->get_value(),
            '',
            "Pre RegEx data is successfully saved"
        );

        is(
            $Selenium->find_element( "#PreKey_3", 'css' )->get_value(),
            $RandomID . 'PreKey_3',
            "Pre RegEx data is successfully saved"
        );

        is(
            $Selenium->find_element( "#PreValue_3", 'css' )->get_value(),
            $RandomID . 'PreValue_3',
            "Pre RegEx data is successfully saved"
        );

        is(
            $Selenium->find_element( "#PostKey_1", 'css' )->get_value(),
            $RandomID . 'PostKey_1',
            "Post RegEx data is successfully saved"
        );

        is(
            $Selenium->find_element( "#PostValue_1", 'css' )->get_value(),
            $RandomID . 'PostValue_1',
            "Post RegEx data is successfully saved"
        );

        # Delete test created web service.
        my $Success = $WebserviceObject->WebserviceDelete(
            ID     => $WebserviceID,
            UserID => 1,
        );
        ok(
            $Success,
            "Web service ID $WebserviceID is deleted"
        );

        # Make sure cache is correct.
        $Kernel::OM->Get('Kernel::System::Cache')->CleanUp( Type => 'Webservice' );
    }
);

done_testing;
