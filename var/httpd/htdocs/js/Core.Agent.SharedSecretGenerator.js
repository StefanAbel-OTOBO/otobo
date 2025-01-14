// --
// OTOBO is a web-based ticketing system for service organisations.
// --
// Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
// Copyright (C) 2019-2025 Rother OSS GmbH, https://otobo.io/
// --
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
// --

"use strict";

var Core = Core || {};
Core.Agent = Core.Agent || {};

/**
 * @namespace Core.Agent.SharedSecretGenerator
 * @memberof Core.Agent
 * @author
 * @description
 *      This namespace contains the special module functions for the AgentPreferences module.
 */
Core.Agent.SharedSecretGenerator = (function (TargetNS) {

    /**
     * @name Init
     * @memberof Core.Agent.SharedSecretGenerator
     * @function
     * @description
     *      This function initializes the module functionality.
     */
    TargetNS.Init = function () {

        var letters = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "2", "3", "4", "5", "6", "7"];
        var i, r, tempLetter, sharedSecret;

        $("#UserGoogleAuthenticatorSecretKey").parent().append("<button id=\"GenerateUserGoogleAuthenticatorSecretKey\" type=\"button\" class=\"CallForAction\"><span>" + Core.Language.Translate("Generate") + "</span></button>");
        $("#UserGoogleAuthenticatorSecretKey + button").on("click", function(){
            sharedSecret = "";

            for (i = 0; i < letters.length; i++) {
                r = Math.floor(Math.random() * letters.length);
                tempLetter = letters[i];
                letters[i] = letters[r];
                letters[r] = tempLetter;
            }

            for (i = 0; i < 16; i++) {
                sharedSecret += letters[i];
            }

            $("#UserGoogleAuthenticatorSecretKey").val(sharedSecret);
       });
    }

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Agent.SharedSecretGenerator || {}));
