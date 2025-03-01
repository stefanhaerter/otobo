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
Core.UI = Core.UI || {};

/**
 * @namespace Core.UI.Notification
 * @memberof Core.UI
 * @author
 * @description
 *      Popup windows.
 */
Core.UI.Notification = (function (TargetNS) {
    /**
     * @private
     * @name Notification
     * @memberof Core.UI.Notification
     * @member {Object}
     * @description
     *      Notification object.
     */
    var Notification = window.Notification || window.mozNotification || window.webkitNotification;

    /**
     * @name RequestPermission
     * @memberof Core.UI.Notification
     * @function
     * @returns {Boolean} True/false if notifications have been allowed.
     * @description
     *      This function requests notification permissions from a browser.
     */
    TargetNS.RequestPermission = function () {
        return Notification.requestPermission(function (Result) {
            if (Result === 'denied' || Result === 'default') {
                return false;
            }
            return true;
        });
    };

    /**
     * @name Show
     * @memberof Core.UI.Notification
     * @function
     * @returns {Boolean} True/false if notification is showed.
     * @param {String} Header - A header for notification
     * @param {String} Body - Body of notification.
     * @param {Integer} Sticky - should notification be sticky until it's closed.
     * @param {String} Icon - Path to the icon for the notification.
     * @param {String} Action - Action to lead on click on notification.
     * @description
     *      This function opens a popup window. Every popup is of a specific type and there can only be one window of a type at a time.
     */
    TargetNS.Show = function (Header, Body, Sticky, Icon, Action) {

        var Options,
            NewNotification;

        // Fallback mechanism for old browsers
        if (!Notification) {

            // Just alert Header and Body and return true
            alert(Header + " \n " + Body);
            return true;
        }

        if (Sticky === 1) {
            Sticky = true;
        } else {
            Sticky = false;
        }

        // Request permissions
        return Notification.requestPermission(function (Result) {
            if (Result === 'denied' || Result === 'default') {
                return false;
            }

            Options = {
                body: Body,
                sticky: Sticky,
                icon: Icon,
                vibrate: [200, 100, 200]
            };

            NewNotification = new Notification(Header, Options);

            // If action parameter is passed
            if (Action) {
                NewNotification.onclick = function () {
                    window.location.href = Core.Config.Get('Baselink') + "Action=" + Action;

                    // Close this notification
                    NewNotification.close();
                };
            }

            return true;
        });
    };

    return TargetNS;
}(Core.UI.Notification || {}));
