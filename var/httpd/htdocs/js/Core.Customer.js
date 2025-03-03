// --
// OTOBO is a web-based ticketing system for service organisations.
// --
// Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
// Copyright (C) 2019-2022 Rother OSS GmbH, https://otobo.de/
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

/**
 * @namespace Core.Customer
 * @memberof Core
 * @author
 * @description
 *      This namespace contains all global functions for the customer interface.
 */
Core.Customer = (function (TargetNS) {
    if (!Core.Debug.CheckDependency('Core.Customer', 'Core.UI', 'Core.UI')) {
        return false;
    }
    if (!Core.Debug.CheckDependency('Core.Customer', 'Core.Form', 'Core.Form')) {
        return false;
    }
    if (!Core.Debug.CheckDependency('Core.Customer', 'Core.Form.Validate', 'Core.Form.Validate')) {
        return false;
    }
    if (!Core.Debug.CheckDependency('Core.Customer', 'Core.UI.Accessibility', 'Core.UI.Accessibility')) {
        return false;
    }
    if (!Core.Debug.CheckDependency('Core.Agent', 'Core.UI.InputFields', 'Core.UI.InputFields')) {
        return false;
    }

    /**
     * @name SupportedBrowser
     * @memberof Core.Customer
     * @member {Boolean}
     * @description
     *     Indicates a supported browser.
     */
    TargetNS.SupportedBrowser = true;

    /**
     * @name IECompatibilityMode
     * @memberof Core.Customer
     * @member {Boolean}
     * @description
     *     IE Compatibility Mode is active.
     */
    TargetNS.IECompatibilityMode = false;

    /**
     * @name Init
     * @memberof Core.Customer
     * @function
     * @description
     *      This function initializes the application and executes the needed functions.
     */
    TargetNS.Init = function () {
        TargetNS.SupportedBrowser = Core.App.BrowserCheck('Customer');
        TargetNS.IECompatibilityMode = Core.App.BrowserCheckIECompatibilityMode();

        if (TargetNS.IECompatibilityMode) {
            TargetNS.SupportedBrowser = false;
            alert(Core.Language.Translate('Please turn off Compatibility Mode in Internet Explorer!'));
        }

        if (!TargetNS.SupportedBrowser) {
            alert(
                Core.Language.Translate('The browser you are using is too old.')
                + ' '
                + Core.Language.Translate('This software runs with a huge lists of browsers, please upgrade to one of these.')
                + ' '
                + Core.Language.Translate('Please see the documentation or ask your admin for further information.')
            );
        }

        // check if we're on a touch device and on the regular resolution (non-mobile). If that's the case,
        // don't allow triggering the link on "parent" elements directly, they should only expand the sub menu
        Core.App.Responsive.CheckIfTouchDevice();
        $('#Navigation > ul > li > a').on('click', function(Event) {
            if (Core.App.Responsive.IsTouchDevice() && $(this).next('ul:visible').length && Core.App.Responsive.GetScreenSize() === 'ScreenXL') {
                Event.preventDefault();
                Event.stopPropagation();
            }
        });

        // unveil full error details only on click
        $('.TriggerFullErrorDetails').on('click', function() {
            $('.Content.ErrorDetails').toggle();
        });

        // move customer notifications between header and content
        $('#oooCustomerNotifications').insertAfter('#oooHeader');
        if ($('#oooCustomerNotifications > div').length == 0) {
            $('#oooCustomerNotifications').hide();
        }
    };

    /**
     * @name ClickableRow
     * @memberof Core.Customer
     * @function
     * @description
     *      This function makes the whole row in the MyTickets and CompanyTickets view clickable.
     */
    TargetNS.ClickableRow = function(){
        $("table tr").click(function(){
            window.location.href = $("a", this).attr("href");
            return false;
        });
    };

    /**
     * @name Enhance
     * @memberof Core.Customer
     * @function
     * @description
     *      This function adds the class 'JavaScriptAvailable' to the 'Body' div to enhance the interface (clickable rows).
     */
    TargetNS.Enhance = function(){
        $('body').removeClass('NoJavaScript').addClass('JavaScriptAvailable');
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_GLOBAL_EARLY');

    return TargetNS;
}(Core.Customer || {}));
