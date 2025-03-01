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
Core.Agent = Core.Agent || {};
Core.Agent.Admin = Core.Agent.Admin || {};

/**
 * @namespace Core.Agent.Admin.GenericInterfaceErrorHandling
 * @memberof Core.Agent.Admin
 * @author
 * @description
 *      This namespace contains the special functions for the GenericInterface request retry module.
 */
Core.Agent.Admin.GenericInterfaceErrorHandling = (function (TargetNS) {

    /**
     * @name Init
     * @memberof Core.Agent.Admin.GenericInterfaceErrorHandling
     * @function
     * @description
     *      Initializes the module functions.
     */
    TargetNS.Init = function () {

        TargetNS.ErrorHandling = Core.Config.Get('ErrorHandling');

        $('#DeleteButton').on('click', TargetNS.ShowDeleteDialog);

    };

   /**
     * @name ShowDeleteDialog
     * @memberof Core.Agent.Admin.GenericInterfaceErrorHandling
     * @function
     * @param {Object} Event - Event object of the clicked element.
     * @description
     *      This function shows a confirmation dialog with 2 buttons.
     */
    TargetNS.ShowDeleteDialog = function(Event){
        Core.UI.Dialog.ShowContentDialog(
            $('#DeleteDialogContainer'),
            Core.Language.Translate('Delete error handling module'),
            '240px',
            'Center',
            true,
            [
               {
                   Label: Core.Language.Translate('Cancel'),
                   Class: 'Primary',
                   Function: function () {
                       Core.UI.Dialog.CloseDialog($('#DeleteDialog'));
                   }
               },
               {
                   Label: Core.Language.Translate('Delete'),
                   Function: function () {
                       var Data = {
                            Action: 'AdminGenericInterfaceErrorHandlingDefault',
                            Subaction: 'DeleteAction',
                            CommunicationType: TargetNS.ErrorHandling.CommunicationType,
                            ErrorHandling: TargetNS.ErrorHandling.ErrorHandlingModule,
                            WebserviceID: TargetNS.ErrorHandling.WebserviceID,
                            ErrorHandlingType: TargetNS.ErrorHandling,
                            Confirmed: '1'
                        };

                        Core.AJAX.FunctionCall(Core.Config.Get('CGIHandle'), Data, function (Response) {
                            if (!Response || !Response.Success) {
                                alert(Core.Language.Translate('An error occurred during communication.'));
                                return;
                            }

                            Core.App.InternalRedirect({
                                Action: 'AdminGenericInterfaceWebservice',
                                Subaction: 'Change',
                                WebserviceID: TargetNS.ErrorHandling.WebserviceID
                            });

                        }, 'json');

                       Core.UI.Dialog.CloseDialog($('#DeleteDialog'));
                   }
               }
           ]
        );

        Event.stopPropagation();
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Agent.Admin.GenericInterfaceErrorHandling || {}));
