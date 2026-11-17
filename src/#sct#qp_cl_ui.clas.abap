CLASS /sct/qp_cl_ui DEFINITION
  PUBLIC
  INHERITING FROM /sct/qp_cl_ui_root_app
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_token,
        id    TYPE string,
        index TYPE int4,
        add   TYPE /sct/qp_if_fcat=>tty_token,
        del   TYPE /sct/qp_if_fcat=>tty_token,
        tok   TYPE /sct/qp_if_fcat=>tty_token,
      END OF ty_token.
    TYPES tty_token TYPE STANDARD TABLE OF ty_token WITH DEFAULT KEY.
    TYPES:
      BEGIN OF ty_global,
        layout             TYPE string,
        previous_layout    TYPE string,
        selection_expanded TYPE abap_bool,
        t_selfields        TYPE /sct/qp_if_ui_selection=>ty_t_input,
        select             TYPE /sct/qp_if_ui_selection=>ty_s_select,
        settings           TYPE /sct/qp_if_ui_root_app=>ty_settings,
        settings_old       TYPE /sct/qp_if_ui_root_app=>ty_settings,
        context            TYPE /sct/qp_if_ui_root_app=>ty_context,
        data               TYPE /sct/au5_if_types=>ty_t_name_value,
      END OF ty_global.
    TYPES:
      BEGIN OF ty_param,
        start_stateful TYPE abap_bool,
        tree           TYPE abap_bool,
      END OF ty_param.

    DATA ms_globals            TYPE ty_global.
    DATA mt_last_shown_arg     TYPE string_table.
    DATA mv_check_timer_active TYPE abap_bool.
    DATA mv_new_tab_url        TYPE string.

    CONSTANTS c_mime_path TYPE string VALUE '/sap/public/bc/WebIcons/de.secat.qppd/' ##NO_TEXT.

    DATA mt_scroll       TYPE /sct/au5_if_types=>ty_t_name_value.
    DATA mv_scrollupdate TYPE abap_bool.

    METHODS constructor.

    METHODS /sct/au5_if_app~main            REDEFINITION.
    METHODS /sct/qp_if_ui_app~display       REDEFINITION.
    METHODS /sct/qp_if_ui_app~init          REDEFINITION.
    METHODS /sct/qp_if_ui_app~process_fcode REDEFINITION.
    METHODS /sct/qp_if_ui_app~set_stateful  REDEFINITION.
    METHODS /sct/qp_if_ui_root_app~callback                       " AD, 2026.10.09, changed
                                            REDEFINITION.
    METHODS /sct/qp_if_ui_root_app~get_context                    " AD, 2026.10.09, changed
                                               REDEFINITION.
    METHODS /sct/qp_if_ui_root_app~get_data                       " AD, 2026.10.09, changed
                                            REDEFINITION.
    METHODS /sct/qp_if_ui_root_app~get_footer                     " AD, 2026.10.09, changed
                                              REDEFINITION.
    METHODS /sct/qp_if_ui_root_app~get_settings                   " AD, 2026.10.09, changed
                                                REDEFINITION.
    METHODS /sct/qp_if_ui_root_app~popover_close                  " AD, 2026.10.09, changed
                                                 REDEFINITION.
    METHODS /sct/qp_if_ui_root_app~popover_open                   " AD, 2026.10.09, changed
                                                REDEFINITION.
    METHODS /sct/qp_if_ui_root_app~set_data                       " AD, 2026.10.09, changed
                                            REDEFINITION.
    METHODS /sct/qp_if_ui_root_app~set_next_event                 " AD, 2026.10.09, changed
                                                  REDEFINITION.
    METHODS /sct/qp_if_ui_root_app~set_stringify                  " AD, 2026.10.09, changed
                                                 REDEFINITION.
    METHODS /sct/qp_if_ui_root_app~snap_selection                 " AD, 2026.10.09, changed
                                                  REDEFINITION.
    METHODS /sct/qp_if_ui_app~actualize_bindings REDEFINITION.

  PROTECTED SECTION.
    ALIASES get_location FOR /sct/qp_if_ui_app~get_location.

    DATA ms_params              TYPE ty_param.
    DATA mo_ui_detail           TYPE REF TO /sct/qp_if_ui_detail.
    DATA mo_ui_selection        TYPE REF TO /sct/qp_if_ui_selection.
    DATA mo_ui_objlist_root     TYPE REF TO /sct/qp_if_ui_objlist_root.
    DATA mo_ui_objlist_child    TYPE REF TO /sct/qp_if_ui_objlist_child.
    DATA mv_stringify           TYPE abap_bool.
    DATA mv_popover             TYPE abap_bool.
    DATA mv_popover_close_event TYPE string.
    DATA mo_ui_tree_mt          TYPE REF TO /sct/qp_if_ui_tree_mt.

    METHODS init_scroll.
    METHODS set_scrollpos_after_redraw.
    METHODS do_js.
    METHODS do_display        RAISING   /sct/qp_cx_error.
    METHODS init_inst.
    METHODS do_display_detail RAISING   /sct/qp_cx_error.
    METHODS do_settings       IMPORTING id TYPE csequence.

    METHODS do_display_navigation IMPORTING io_flexible_column_layout TYPE REF TO /sct/au5_cl_xml_view
                                  RAISING   /sct/qp_cx_error.

    METHODS process_show_data                                                       " AD, 2026.10.09, changed
                              IMPORTING is_get TYPE /sct/au5_if_client=>ty_s_get.

    METHODS get_selection                                                           " AD, 2026.10.09, changed
                          CHANGING cs_get TYPE /sct/au5_if_client=>ty_s_get.

    METHODS get_selection_embedded                                                             " AD, 2026.10.09, changed
                                   CHANGING  cs_get        TYPE /sct/au5_if_client=>ty_s_get
                                   RETURNING VALUE(result) TYPE /sct/qp_t_range_guid.

    METHODS do_info            IMPORTING id TYPE string.

    METHODS process_fcode_self REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.


CLASS /sct/qp_cl_ui IMPLEMENTATION.
  METHOD constructor.
    "--------------------------------------------------------------------"
    " Änderungslog
    "--------------------------------------------------------------------"
    " AD, 2025.06.11, NOTE-3592, angelegt
    "--------------------------------------------------------------------"

    super->constructor( ).

    /sct/au5_if_app~id_app = 'QPPD_UI5'.
    "$TODO
    "/sct/au5_if_app~app_version = '2026/03'.
    "/sct/au5_if_app~app_link = 'https://qppd.info'.

    ms_globals-selection_expanded = abap_true.

    ms_params-start_stateful = abap_false.
*    ms_globals-settings-selected_on_top = abap_true.
    IF sy-uname = 'TROMFRA'.
      ms_globals-settings-disp_app_state = abap_true.
*      ms_globals-settings-save_scroll = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD do_display.
    "--------------------------------------------------------------------"
    " Änderungslog
    "--------------------------------------------------------------------"
    " AD, 2025.06.11, NOTE-3592, angelegt
    "--------------------------------------------------------------------"

*    " Hauptseite
* Haupt-view vor process fcode anlegen damit Popup in Stateless mode erzeugt werden können
*    ms_control-parent_view = /sct/au5_cl_xml_view=>factory( )->page( " title          = 'QPPD'
*                                                                     navbuttonpress = ms_control-client->_event( mcu->events-back )
*                                                                     shownavbutton  = xsdbool( ms_control-client->get( )-s_draft-id_prev_app_stack IS NOT INITIAL )
*                                                                     floatingfooter = abap_true ).

    " Kontrollieren ob es ungespeicherte Änderungen gibt. Falls ja wird im Browser ein Popup geworfen, sollte der Tab geschlossen werden.
    mv_unsaved_state = mo_controller->get_changed_status( ).
    IF mv_unsaved_state IS NOT INITIAL.
      ms_control-parent_view->invisible_text( ns   = 'core'
                                              id   = 'unsaved_state'
                                              text = 'X' ).
    ENDIF.

    DATA(lo_dyn_page) = ms_control-parent_view->dynamic_page( showfooter     = abap_true
                                                              headerexpanded = ms_control-client->_bind( ms_globals-selection_expanded ) ).

    " Browser-event triggern, sobald mv_check_timer_active = true
    " aktuell nur zur Navigation in einem anderen Tab.
    ms_control-parent_view->_sctau5( )->timer( checkactive = ms_control-client->_bind( mv_check_timer_active )
                                               finished    = ms_control-client->_event_client( val   = ms_control-client->cs_event-open_new_tab
                                                                                               t_arg = VALUE #( ( |${ ms_control-client->_bind( mv_new_tab_url ) }| ) ) ) ).
*
*    " Hiermit kann man die Scrollposition von vordefinierten HTML-Elementen lesen
    IF ms_globals-settings-save_scroll = abap_true.
      " Nur in stateless Mode benötigt
      ms_control-parent_view->_sctau5( )->scrolling( setupdate = ms_control-client->_bind( mv_scrollupdate )
                                                     items     = ms_control-client->_bind( mt_scroll ) ).
    ENDIF.
    IF ms_globals-context-embedded = abap_false.
      " *********************************************************************
      " HEADER
      " *********************************************************************
      DATA(lo_header_title) = lo_dyn_page->title( ns = 'f' )->get( )->dynamic_page_title( ).

      IF ms_globals-settings-disp_app_state = abap_true.
        IF is_stateful( ).
          DATA(lv_state) = |({ mutx->get_text( mutx->n113 ) })|.
        ELSE.
          lv_state = |({ mutx->get_text( mutx->n114 ) })|.
        ENDIF.
      ENDIF.

      " Kopf aufbauen
      DATA(lv_text) = |{ mutx->get_text( mutx->u001 ) } { lv_state }|.

*    lo_header_title->heading( 'f' )->title( lv_text ). " UI5 Applikation für QPPD

*    DATA(lv_src) = /sct/qp_cl_ui_const=>logo_secat.
      " 'https://s4a.secat.de:1443/sap/public/bc/themes/~client-001/~cache-CRZBSlDj9.71YTe5Sq91Y11JGEk/Base/baseLib/secat_morning_horizon/img/misc/sapCompanyLogo.png'
      " 403 Forbidden        lv_src ='https://S4A.secat.de:1443/sap/public/bc/abap/mime_demo/ABAP_Docu_Logo.gif?sap-client=001'.
      " 404  Not found ???   lv_src = `https://S4A.secat.de:1443/sap/public/bc/UI5/LIBRARIES/com.sap.ui5.commons/META-INF/resources/sap/ui/commons/themes/base/img/ColorPicker/ColorBar.png`. "?sap-client=001`.
      " 404                  lv_src = 'https://S4A.secat.de:1443/sap/public/bc/BILD2.png'. " ?sap-client=001'.
*      lv_src = 'https://S4A.secat.de:1443/sap/public/bc/Icons/Cluster-redIcon.svg'. " ?sap-client=001'.
*      lv_src = 'https://S4A.secat.de:1443/sap/public/bc/pictograms/3_people_money.gif'. " ?sap-client=001'.
*      lv_src = 'https://S4A.secat.de:1443/sap/public/bc/WebIcons/de.secat.qppd/Bild.png'. " ?sap-client=001'.
      DATA(lv_image) = 'Secat.png'.
*      DATA(lv_src) = |{ get_location( c_mime_path ) }{ lv_image }|.
      DATA(lv_src) = |{ c_mime_path }{ lv_image }|.

*    ENDIF.
*    lo_header_title->heading( 'f' )->image( src   = lv_src
*                                            width = '180px'
*                                               ).
***

*    lo_header_title->expanded_content( 'f' )->label( lv_text ). " UI5 Applikation für QPPD
*    lo_header_title->snapped_content( 'f' )->label( lv_text ). " UI5 Applikation für QPPD

      lo_header_title->expanded_content( 'f' )->hbox( justifycontent = 'SpaceBetween'
                                                      alignitems     = 'Center'
                                              )->hbox( alignitems = 'Center'
                                              )->image( src   = lv_src
                                                        width = '180px'
*                                            )->label( text  = lv_text
*                                                        class = 'sapUiSmallMargin'   " UI5 Applikation für QPPD
                                              )->button( id    = 'InfoBtn_E'
                                                         class = 'sapUiTinyMarginBeginEnd'
                                                         text  = lv_text
                                                         type  = mcu->sap-m-buttontype-transparent
*                                                         icon  = 'sap-icon://hint'
                                                         press = _event( iv_name = 'POPOVER_INFO'
                                                                         it_arg  = VALUE #( ( |InfoBtn_E| ) ) )
                                              )->get_parent(
                                              )->button( id      = 'AppSettingsBtn_E'
                                                         class   = 'sapUiTinyMarginBeginEnd'
                                                         text    = ''
                                                         icon    = 'sap-icon://action-settings'
                                                         press   = _event( iv_name = 'SETTINGS'
                                                                           it_arg  = VALUE #( ( |AppSettingsBtn_E| ) ) )
                                                         tooltip = mtx->get_gui_text( mtx->n044 ) ).
      lo_header_title->snapped_content( 'f' )->hbox( justifycontent = 'SpaceBetween'
                                                     alignitems     = 'Center'
                                              )->hbox( alignitems = 'Center'
                                              )->image( src   = lv_src
                                                        width = '180px'
*                                            )->label( text  = lv_text
*                                                        class = 'sapUiSmallMargin'   " UI5 Applikation für QPPD
                                              )->button( id    = 'InfoBtn_S'
                                                         class = 'sapUiTinyMarginBeginEnd'
                                                         text  = lv_text
                                                         type  = mcu->sap-m-buttontype-transparent
*                                                         icon  = 'sap-icon://hint'
                                                         press = _event( iv_name = 'POPOVER_INFO'
                                                                         it_arg  = VALUE #( ( |InfoBtn_S| ) ) )

                                              )->get_parent(
                                              )->button( id      = 'AppSettingsBtn_S'
                                                         class   = 'sapUiTinyMarginBeginEnd'
                                                         text    = ''
                                                         icon    = 'sap-icon://action-settings'
                                                         press   = _event( iv_name = 'SETTINGS'
                                                                           it_arg  = VALUE #( ( |AppSettingsBtn_S| ) ) )
                                                         tooltip = mtx->get_gui_text( mtx->n044 ) ).

    ENDIF.
    " *********************************************************************
    " Footer
    " *********************************************************************
*    mo_footer = ms_control-parent_view->footer( )->overflow_toolbar( visible = ms_globals-footer_visible )->toolbar_spacer( ).

    " *********************************************************************
    " Selektion
    " *********************************************************************
    IF ms_globals-context-embedded = abap_false.
      mo_ui_selection->/sct/qp_if_ui_app~display( io_view   = lo_dyn_page
                                                  io_client = ms_control-client ).
    ENDIF.

    " *********************************************************************
    " Unter dem HEADER
    " *********************************************************************
    DATA(lo_cont) = lo_dyn_page->content( 'f' ).

    DATA(lo_col_layout) = lo_cont->flexible_column_layout( layout = ms_control-client->_bind( ms_globals-layout
*                                                                    _bind( iv_fieldname = 'ms_globals-layout'
*                                                                           ir_data      = REF #( ms_globals-layout )
*                                                                           iv_name      = 'LayoutType'
                                                                           )
                                                           id     = mcu->id-under_header
*                                                           defaulttransitionnamebegincol = `flip`
*                                                           defaulttransitionnameendcol = `fade`
*                                                           defaulttransitionnamemidcol = `flip`
                                                           ).

    " Zuerst Detail dann Navigation: Detail könnte ggfs. mv_stringify setzten
    do_display_detail( ).

    do_display_navigation( lo_col_layout ).

    " *********************************************************************
    " FOOTER
    " *********************************************************************
    " siehe CL_UI_NODE->display

    " *********************************************************************
    " Zusatzfunktionen
    " *********************************************************************

    do_js( ).

    IF mv_stringify = abap_true.
      ms_control-client->view_display( ms_control-parent_view->stringify( ) ).

    ELSE.
      IF 1 = 2.
        " Fürs debugging: "manuelle" Aktualisierung der View
        ms_control-client->view_model_update( ).
        ms_control-client->nest_view_model_update( ).
        ms_control-client->nest2_view_model_update( ).
      ENDIF.
    ENDIF.
    set_scrollpos_after_redraw( ).

    mv_stringify = abap_false.
  ENDMETHOD.

  METHOD /sct/qp_if_ui_app~display.
    IF mv_popover IS NOT INITIAL.
      " Wurde ein Popover angezeigt, dann soll in der Hauptanzeige gar nichts passieren
      RETURN.
    ENDIF.

    "$TODO
    DATA(lo_client) = CAST /sct/au5_cl_ui5_client( ms_control-client ).
    IF lo_client->mo_action->ms_next-o_app_call IS NOT INITIAL.
      " Vor der Navigation zu einer anderen App, muss die Anzeige nicht aktualisiert werden.
      RETURN.
    ENDIF.

    do_display( ).
  ENDMETHOD.

  METHOD process_fcode_self.
    rv_processed = abap_false. " Events grundsätzlich weiterleiten (Objektlisten, Detail )
    " damit die Instanzeninitialisieungen im Stateless-Mode erfolgen kann

    CASE is_get-event.
      WHEN mcu->events-redraw.
        IF mt_last_shown_arg IS NOT INITIAL.
          /sct/qp_if_ui_root_app~set_stringify( ).
          /sct/qp_if_ui_root_app~set_next_event( VALUE #( event       = mcu->events-show_data
                                                          t_event_arg = mt_last_shown_arg ) ).
        ENDIF.

      WHEN mcu->events-toggle_detail_fs.
        IF ms_globals-layout = mcu->sap-f-layouttype-endfullscreen
        OR ms_globals-layout = mcu->sap-f-layouttype-midfullscreen.
          ms_globals-layout = ms_globals-previous_layout.
        ELSE.
          ms_globals-previous_layout = ms_globals-layout.
          IF ms_globals-layout = mcu->sap-f-layouttype-threeendexpanded.
            ms_globals-layout = mcu->sap-f-layouttype-endfullscreen.
          ELSEIF ms_globals-layout = mcu->sap-f-layouttype-twomidexpanded.
            ms_globals-layout = mcu->sap-f-layouttype-midfullscreen.
          ENDIF.
        ENDIF.

      WHEN mcu->events-show_data.
        process_show_data( is_get ).

      WHEN mcu->events-nav_list_clear.
        ms_globals-layout = mcu->sap-f-layouttype-one.
        ms_control-client->view_model_update( ).

      WHEN mcu->events-reset_layout_root.
        ms_globals-layout = mcu->sap-f-layouttype-one.
        ms_control-client->view_model_update( ).

      WHEN mcu->events-reset_layout_child.
        ms_globals-layout = mcu->sap-f-layouttype-twomidexpanded.
        ms_control-client->view_model_update( ).

      WHEN mcu->events-back.
        ms_control-client->nav_app_leave( ).

      WHEN mcu->events-open_new_tab.
        mv_check_timer_active = abap_true.
        mv_new_tab_url = is_get-t_event_arg[ 1 ].
        ms_control-client->view_model_update( ).

      WHEN 'POPOVER_INFO'.
        do_info( id = is_get-t_event_arg[ 1 ] ).

      WHEN 'SETTINGS'.
        ms_globals-settings-max_sel_count = ms_globals-select-max_sel_count.
        ms_globals-settings_old = ms_globals-settings.

        do_settings( id = is_get-t_event_arg[ 1 ] ).

      WHEN 'CLOSE_SETTINGS'.

        IF ms_globals-settings_old <> ms_globals-settings. " Something changed

          mo_cust->get_tusrpref( IMPORTING es_tusrpref = DATA(ls_tusrpref) ).
          ms_globals-select-max_sel_count = ms_globals-settings-max_sel_count.

          " Änderungen persistieren
          ls_tusrpref-maxrows = ms_globals-settings-max_sel_count.
          mo_cust->do_change_tuserpref( is_tusrpref_change = ls_tusrpref ). " Benutzereinstellungen für QV-Cockpit
          COMMIT WORK.

          ms_control-client->view_model_update( ).
        ELSE.
          " Beim setzen des close_Event wird den Screen-Redraw verhindert,

          mv_popover_close_event = is_get-event.
        ENDIF.
*        ms_control-client->message_toast_display( text = `FT20260218: Diese Funktion ist noch nicht implementiert` ).
*      WHEN 'DUMMY'.
*        ms_control-client->follow_up_action( val = ` setScroll();` ).

*      WHEN 'CREATE'.
*

*
*        ms_control-client->nav_app_call( zmb_ui5_popupwiz=>factory( mt_table ) ).
*      WHEN 'HEADER_STATUS'.
*        TYPES:
*          BEGIN OF ty_s_tab,
*            selkz            TYPE abap_bool,
*            product          TYPE string,
*            create_date      TYPE string,
*            create_by        TYPE string,
*            storage_location TYPE string,
*            quantity         TYPE i,
*          END OF ty_s_tab.
*        TYPES ty_t_table TYPE STANDARD TABLE OF ty_s_tab WITH EMPTY KEY.
*        DATA mt_table TYPE ty_t_table.
*        ms_control-client->nav_app_call( zmb_ui5_popupwiz=>factory( mt_table ) ).
    ENDCASE.
  ENDMETHOD.

  METHOD /sct/au5_if_app~main.
    "--------------------------------------------------------------------"
    " Änderungslog
    "--------------------------------------------------------------------"
    " AD, 2025.06.11, NOTE-3592, angelegt
    "--------------------------------------------------------------------"
    TRY.

        DATA(ls_get) = client->get( ).
        ms_globals-context-flp = ls_get-check_launchpad_active.

        init( is_control = VALUE #( client = client ) ). " AD, 2026.10.09, changed
        mv_check_timer_active = abap_false. " Reset needed each time

        IF ms_control-client->check_on_init( ). " 1st call
          get_selection( CHANGING cs_get = ls_get ).
          /sct/qp_if_ui_root_app~set_stringify( ). " Komplett aufbauen
          check_initialized = abap_true.
        ELSEIF ms_control-client->check_on_navigated( ) = abap_true.
          " Eine neue Applikation wurde gestartet ( TOE, Popup aus Objekttypen...) und anschließend geschlossen:
          " Wir navigieren zurück in diese App: nichts tun, es sei denn ein event ist dadurch gefeuert worden
          DATA(ls_callback_event) = /sct/qp_if_ui_root_app~callback( ).
          IF ls_callback_event IS NOT INITIAL.
            ls_get = ls_callback_event.
            " Die Sub-Applikationen mussen vor process_fcode( ) aktualisiert werden, weil ms_control-base zwischendurch verloren geht
            IF mo_ui_detail IS BOUND.
              mo_ui_detail->/sct/qp_if_ui_app~actualize_bindings( ).
            ENDIF.
            " ein kompletten Redraw muss erfolgen, wenn eine Nachfolgefunktion gestartet wird
            " Komplett aufbauen ? Nein, Callback-Event soll verarbeitet werden. Diese App soll entscheiden
            " Hat kein Zweck : sobald eine Aktualisierung erfolgen muss ( callback macht schon irgend etwas ansonsten soll man kein Callback befüllen),
            " wird sein Stringify notwendig, weil wir aus einer anderen App zurückkommen und selbst in stateful mode müssen einige Sachen neuaufgemaut werden
            " bis ich gefunden habe, wie es zu vermeinden ist.
            /sct/qp_if_ui_root_app~set_stringify( ).
          ELSE.
*          ms_control-client->popup_destroy( ).
*          ms_control-client->view_model_update( ).
*          ms_control-client->nest_view_model_update( ).
*          ms_control-client->nest2_view_model_update( ).

            " Die aufgerufene Applikationen reagieren anders wenn sie geschlossen werden...
            " F4 -POPUP funktioniert sauber ohne return ( ie normale Verarbeitung )
            " Preview POPUP ( DOCS ) wird sauber geschlossen in stateful mode aber nicht im stateless (bleibt im Vordergrund)
            " Der App Redraw in stateful mode ist nicht iO,
            "        ls_get-event = mcu->events-redraw.
            "        /sct/qp_if_ui_root_app~set_stringify( ). " Komplett aufbauen

            " Kein RETURN sonst wird nach F4POPUP-Cancel die Anzeige nicht sauber wiederaufgebaut
            " Doch RETURN weil das Bildschirm nicht mehr umsonst aktualisiert wurde, das Popup kann einfach geschlossen werden ohne weitere Verarbeitung

            " selbst wenn ab jetzt wegen return nichts mehr passiert, wird mv_stringify gesetzt, damit bei der nächste Aktion ggfs. der Screen neuaufgebaut wird.
            /sct/qp_if_ui_root_app~set_stringify( ).
            RETURN.
          ENDIF.
        ENDIF.

        " Profil bei jeden Aufruf ins Handler neu setzen, dadurch können die excluded actions beeinflusst werden.
        mo_ui_handler->mv_profile = ms_globals-context-profile.

        " Alle Popovers werden hier zentral geschlossen, egal welche subApp das Popover geöffnet hat
        IF mv_popover IS NOT INITIAL.
          ms_control-client->popover_destroy( ).
          CLEAR mv_popover.

        ENDIF.

        " Hauptseite vor PROCESS_FCODE aufbereiten (der Wizard braucht ein vohandenes view )
        ms_control-parent_view = /sct/au5_cl_xml_view=>factory( )->page( " title          = 'QPPD'
                                                                         navbuttonpress = ms_control-client->_event( mcu->events-back )
                                                                         shownavbutton  = xsdbool( ms_control-client->get( )-s_draft-id_prev_app_stack IS NOT INITIAL )
                                                                         floatingfooter = abap_true ).

        CLEAR /sct/qp_if_ui_root_app~mt_next_events.
        /sct/qp_if_ui_app~actualize_bindings( ).

        DATA(lv_layout) = ms_globals-layout.
        process_fcode( is_get    = ls_get
                       io_client = client ). " AD, 2026.10.09, changed

        " Beim Schließen eines Popups erfolgt keine Aktualisierung wenn event = close_event
        " Konsequenz : wird close_event nicht gesetzt dann erflogt ein Redraw beim Schließen des Popovers
        IF ls_get-event IS NOT INITIAL AND mv_popover_close_event = ls_get-event.
          RETURN.
        ENDIF.

        IF lv_layout <> ms_globals-layout.
          ms_globals-previous_layout = lv_layout.

          " Beim zurück aus Vollbild ist ein Stringify notwendig wenn z.B vorher une andere App (Suchhilfe) aufgerufen worden ist.
          IF is_stateful( ) AND ( lv_layout <> mcu->sap-f-layouttype-endfullscreen AND lv_layout <> mcu->sap-f-layouttype-midfullscreen ).
            ms_control-client->view_model_update( ).
*        ms_control-client->nest_view_model_update( ).
*        ms_control-client->nest2_view_model_update( ).
          ELSE.
            /sct/qp_if_ui_root_app~set_stringify( ). " Komplett aufbauen
          ENDIF.
        ENDIF.

        display( io_client = client " AD, 2026.10.09, changed
                 io_view   = VALUE #( ) ).

      CATCH /sct/qp_cx_error INTO DATA(lo_error).
        " QPPD-seitig ist irgendwas scheifgegangen.
        do_show_message( it_return  = VALUE #( ( lo_error->get_msg_bapiret( ) ) )
                         iv_msgtype = /sct/qp_cl_const=>msgtype_e ).

    ENDTRY.
  ENDMETHOD.

  METHOD /sct/qp_if_ui_root_app~get_footer.
*    ms_globals-footer_visible = abap_true.
    ro_view = ms_control-parent_view->footer( )->overflow_toolbar(
*                                                                  visible = ms_globals-footer_visible
                                                                 )->toolbar_spacer( ).
*ro_view = mo_footer.
  ENDMETHOD.

  METHOD process_show_data.
    " Bestimmung des Layouts anhand des anzuzeigenden Knotens (Layout mit 2 oder 3 Bereiche)
    " Das Layout kann ebenfalls mit der TOGGLE-Fullscreen Funktion beeiflusst werden.

    " *********************************************************************
    " Kinder Obj List Nested View
    " *********************************************************************

    IF is_get-t_event_arg[ 1 ] = is_get-t_event_arg[ 2 ].
      DATA(lt_arg) = is_get-t_event_arg.
      " Zusatzprüfung Existenz von Kinder unter Root
      IF NOT line_exists( is_get-t_event_arg[ table_line = mcu->sap-m-listtype-active ] )
      OR NOT line_exists( is_get-t_event_arg[ table_line = mcu->sap-m-listtype-navigation ] ).
        DATA(lr_base_root) = mo_ui_handler->get_hierarchy( iv_guid     = CONV #( is_get-t_event_arg[ 1 ] )
                                                           iv_oguid    = CONV #( is_get-t_event_arg[ 1 ] )
                                                           iv_stateful = is_stateful( ) ).
        INSERT COND #( WHEN lr_base_root->instance->mt_childs IS INITIAL
                       THEN mcu->sap-m-listtype-active
                       ELSE mcu->sap-m-listtype-navigation ) INTO TABLE lt_arg.
      ENDIF.

      IF ms_globals-layout = mcu->sap-f-layouttype-endfullscreen OR ms_globals-layout = mcu->sap-f-layouttype-midfullscreen.
      " Keine Anpassung in Fullscreen
      ELSE.
        IF NOT line_exists( lt_arg[ table_line = mcu->sap-m-listtype-navigation ] ).
          " Der Root Knoten hat keine Kinder -> Kein mittleren Bereich
          ms_globals-layout = mcu->sap-f-layouttype-twomidexpanded.
        ELSE.
          ms_globals-layout = mcu->sap-f-layouttype-threeendexpanded.
        ENDIF.
      ENDIF.

    ELSE.
      IF ms_globals-layout = mcu->sap-f-layouttype-endfullscreen OR ms_globals-layout = mcu->sap-f-layouttype-midfullscreen.
      " Keine Anpassung in Fullscreen
      ELSE.
        ms_globals-layout = mcu->sap-f-layouttype-threeendexpanded.
      ENDIF.
    ENDIF.

    " OGUID GUID zum zuletzt angezeigten Knoten merken, damit beim zürückkommen von einer anderen App
    " ( z.B POPUP-Callback ) die Anzeige wiederherstellt werden kann
    mt_last_shown_arg = is_get-t_event_arg.
    DELETE mt_last_shown_arg FROM 3.
  ENDMETHOD.

  METHOD /sct/qp_if_ui_root_app~set_stringify.
    mv_stringify = abap_true.
  ENDMETHOD.

  METHOD /sct/qp_if_ui_root_app~popover_close.
    CLEAR mv_popover.
*           mv_popover_close_event.
  ENDMETHOD.

  METHOD /sct/qp_if_ui_root_app~popover_open.
    mv_popover = abap_true.
    mv_popover_close_event = iv_close_event.
  ENDMETHOD.

  METHOD /sct/qp_if_ui_app~init.
    super->/sct/qp_if_ui_app~init( is_control ).

    " Falls man die FLP Einstellungen lesen will...
    " um z.B erkennen ob Fiori mit dark mode oder nicht.
    IF ms_globals-context-flp = abap_true OR ms_globals-context-embedded = abap_true.

*      " TODO: variable is assigned but never used (ABAP cleaner)
*      /ui2/cl_flp_session_data=>get_session_data( IMPORTING es_session_data = DATA(ls_session_data) ).
*
*      DATA(lo_user_prof) = NEW /ui2/cl_user_profile(   /ui2/cl_user_profile=>gc_shell_type-flp  ).
*      lo_user_prof->get_user_profile( EXPORTING iv_id           = CONV #( sy-uname )
*                                      IMPORTING
*                                      " TODO: variable is assigned but never used (ABAP cleaner)
*                                                et_user_profile = DATA(lt_up) ).

    ENDIF.

    init_inst( ).
    ms_control-id = mcu->id-root.

    IF ms_params-start_stateful = abap_true.
      set_stateful( ).
    ENDIF.
    init_scroll( ).

    IF ms_globals-layout IS INITIAL.
      ms_globals-layout = mcu->sap-f-layouttype-one.
    ENDIF.
*
*
*    IF is_stateful( ) = abap_false.
*      CLEAR ms_appdata-detail.
*    ENDIF.

    " Die Selektion registrieren
    DATA(lr_sel) = do_insert_sub_app( is_sub_app = VALUE #( id  = mcu->id-selection
                                                            app = mo_ui_selection ) ).

    " Selektion initialisieren
    mo_ui_selection->/sct/qp_if_ui_app~init( is_control = VALUE #( client     = ms_control-client
                                                                   root_app   = me
                                                                   parent_app = me
                                                                   id         = lr_sel->id ) ).
*    IF mv_object_list_active = abap_true.

    " ObjectList Root registrieren
    DATA(lr_root) = do_insert_sub_app( is_sub_app = VALUE #( id  = mcu->id-objl_root
                                                             app = mo_ui_objlist_root ) ).
    mo_ui_objlist_root->/sct/qp_if_ui_app~init( is_control = VALUE #( client     = ms_control-client
                                                                      root_app   = me
                                                                      parent_app = me
                                                                      id         = lr_root->id ) ).

    " Das Obj List Kinder registrieren
    DATA(lr_child) = do_insert_sub_app( is_sub_app = VALUE #( id  = mcu->id-objl_child
                                                              app = mo_ui_objlist_child ) ).

    mo_ui_objlist_child->/sct/qp_if_ui_app~init( is_control = VALUE #( client     = ms_control-client
                                                                       root_app   = me
                                                                       parent_app = me
                                                                       id         = lr_child->id ) ).
    " Das DETAIL registrieren
    DATA(lr_det) = do_insert_sub_app( is_sub_app = VALUE #( id  = mcu->id-detail
                                                            app = mo_ui_detail ) ).

    " DETAIL erst einmal initialisieren
    mo_ui_detail->/sct/qp_if_ui_app~init( is_control = VALUE #( client     = ms_control-client
                                                                root_app   = me
                                                                parent_app = me
                                                                id         = lr_det->id ) ).

*    IF ms_params-tree = abap_true.
*
*      do_insert_sub_app( is_sub_app = VALUE #( id  = 'MT'
*                                               app = mo_ui_tree_mt ) ).
*      mo_ui_tree_mt->/sct/qp_if_ui_app~init( is_control = VALUE #( client     = ms_control-client
*                                                                   root_app   = me
*                                                                   parent_app = me
*                                                                   path       = mt_sub_app[ id = 'MT' ]-path ) ).
*
*      DELETE mt_sub_app WHERE id = 'OLR' OR id = 'OLC'.
*    ENDIF.
  ENDMETHOD.

  METHOD get_selection.
    TRY.

        " GUIDs der Übergabe holen
        DATA(lt_guid) = mo_ui_handler->get_guids_from_ui_guid_string( iv_guids = cs_get-t_comp_params[ n = mc->fname_guid ]-v ).

      CATCH cx_sy_itab_line_not_found.
        IF cs_get-check_launchpad_active = abap_false.
          " GUID aus der URL extrahieren.
          cs_get-s_config-search = to_upper( cs_get-s_config-search ).
          SPLIT cs_get-s_config-search AT 'GUID=' INTO DATA(lv_part1) DATA(lv_part2).
          IF lv_part2 IS NOT INITIAL.
            " TODO: variable is assigned but never used (ABAP cleaner)
            SPLIT lv_part2 AT '&' INTO DATA(lv_guids) DATA(others).
            lt_guid = mo_ui_handler->get_guids_from_ui_guid_string( iv_guids = lv_guids ).
          ENDIF.

          " VNRVVS aus der URL extrahieren.
          SPLIT cs_get-s_config-search AT 'VNRVVS=' INTO lv_part1 lv_part2.
          IF lv_part2 IS NOT INITIAL.
            SPLIT lv_part2 AT '&' INTO DATA(lv_vnrvvs) others.
            lt_guid = mo_ui_handler->get_guids_from_ui_vnr_string( lv_vnrvvs ).
          ENDIF.

        ENDIF.
    ENDTRY.

    DATA(lt_guid_embedded) = get_selection_embedded( CHANGING cs_get = cs_get ).
    IF ms_globals-context-embedded = abap_true.
      lt_guid = lt_guid_embedded.
    ENDIF.

    IF lt_guid IS NOT INITIAL.
      snap_selection( ).
    ENDIF.

    IF lt_guid IS NOT INITIAL.
      " Liste sofort anzeigen
      cs_get-event       = mcu->events-nav_list_build.
      cs_get-t_event_arg = VALUE #( FOR <ls_guid> IN lt_guid
                                    ( CONV #( <ls_guid>-low ) ) ).

    ENDIF.
  ENDMETHOD.

  METHOD init_inst.
    " Die Instanzen der nicht Serialisierbaren Klassen verschwinden zwischen 2 Stateless-Aufrufe

    /sct/qp_cl_factory=>get_instance( CHANGING co_instance = mcu ).
    /sct/qp_cl_factory=>get_instance( CHANGING co_instance = mtx ).
    /sct/qp_cl_factory=>get_instance( CHANGING co_instance = mutx ).
    /sct/qp_cl_factory=>get_instance( CHANGING co_instance = mo_ui_handler ).

    /sct/qp_cl_factory=>get_instances( IMPORTING eo_cust       = mo_cust
                                                 eo_bus        = mo_bus
                                                 eo_conv       = mo_conv
                                                 eo_controller = mo_controller ).

    " Serialisierbare Klassen behalten ihre Attrbute zwischen zwischen 2 Stateless-Aufrufe.
    " Existiert die Instanz schon dann soll sie nicht ersetzt werden
    IF mo_ui_detail IS NOT BOUND.
      /sct/qp_cl_factory=>get_instance( CHANGING co_instance = mo_ui_detail ).
    ENDIF.
    IF mo_ui_selection IS NOT BOUND.
      /sct/qp_cl_factory=>get_instance( CHANGING co_instance = mo_ui_selection ).
    ENDIF.
    IF mo_ui_tree_mt IS NOT BOUND AND ms_params-tree = abap_true.
      /sct/qp_cl_factory=>get_instance( CHANGING co_instance = mo_ui_tree_mt ).
    ENDIF.
    IF mo_ui_objlist_root IS NOT BOUND.
      /sct/qp_cl_factory=>get_instance( CHANGING co_instance = mo_ui_objlist_root ).
    ENDIF.
    IF mo_ui_objlist_child IS NOT BOUND.
      /sct/qp_cl_factory=>get_instance( CHANGING co_instance = mo_ui_objlist_child ).
    ENDIF.
    ms_control-root_app = me.
  ENDMETHOD.

  METHOD /sct/qp_if_ui_root_app~snap_selection.
    ms_globals-selection_expanded = abap_false.
  ENDMETHOD.

  METHOD /sct/qp_if_ui_app~set_stateful.
    success = abap_false.

    IF iv_stateful = check_sticky.
      " Bereits im gleichen zustand, nichts tun.
      success = abap_true.
      RETURN.
    ENDIF.

    CASE iv_stateful.
      WHEN abap_true.
        " stateful setzen ( soll immer funktionieren )
        ms_control-client->set_session_stateful( iv_stateful ).
        success = abap_true.

      WHEN abap_false.
        " zurück in Stateless mode

        IF ms_params-start_stateful = abap_true.
          " nicht möglich wenn die App explizit als Stateful gestartet worden ist
          success = abap_false.
          RETURN.
        ENDIF.

*        IF ms_control-root_app->mv_unsaved_state IS NOT INITIAL.
        IF mo_controller->get_changed_status( ) IS NOT INITIAL.
          " nicht möglich sein, wenn offene Änderungen vorliegen sonst Datenverlust.
          success = abap_false.
*          BREAK-POINT.
          RETURN.
        ENDIF.

        ms_control-client->set_session_stateful( iv_stateful ).
        success = abap_true.
    ENDCASE.
  ENDMETHOD.

  METHOD do_display_detail.
    DATA(lo_view_detail) = /sct/au5_cl_xml_view=>factory( ).

    " Bindings für Log, interne Tabellen… fur alle unter-Applikationen aktualisieren
*    mo_ui_detail->/sct/qp_if_ui_app~actualize_bindings( ).

    " Je nach Layout werden Details auf dem 2. oder 3. Screenbereich angezeigt
    IF ms_globals-layout = mcu->sap-f-layouttype-twomidexpanded
    OR ms_globals-layout = mcu->sap-f-layouttype-midfullscreen.
      ms_control-client->nest_view_model_update( ).

      IF is_stateful( ) = abap_false.
        /sct/qp_if_ui_root_app~set_stringify( ).
      ENDIF.

      " Ist ein Redraw notwendig ( neue ID elemente müssen angezeigt werden ) -> stringify()
      " oder reicht ein update des jeweiligen Models aus
      IF mo_ui_detail->/sct/qp_if_ui_app~must_redraw_nested( )
      OR mv_stringify = abap_true.
        mo_ui_detail->/sct/qp_if_ui_app~display( io_view   = lo_view_detail
                                                 io_client = ms_control-client ).
*        ms_control-client->nest_view_destroy( ).
        ms_control-client->nest_view_display( val            = lo_view_detail->stringify( )
                                              id             = mcu->id-under_header " hier muss die ID stehen, die vorher vergeben wurde!
                                              method_insert  = 'addMidColumnPage'
                                              method_destroy = 'removeAllMidColumnPages' ).
      ENDIF.

    ELSEIF ms_globals-layout = mcu->sap-f-layouttype-threeendexpanded
        OR ms_globals-layout = mcu->sap-f-layouttype-endfullscreen.
      ms_control-client->nest2_view_model_update( ).

      IF is_stateful( ) = abap_false.
*        IF sy-uname = 'TROMFRA'.
*          " Kein Redraw erzwingen.
*        ELSE.
        /sct/qp_if_ui_root_app~set_stringify( ).
*        ENDIF.
      ENDIF.

      IF mo_ui_detail->/sct/qp_if_ui_app~must_redraw_nested( )
      OR mv_stringify = abap_true.

        mo_ui_detail->/sct/qp_if_ui_app~display( io_view   = lo_view_detail
                                                 io_client = ms_control-client ).

*        ms_control-client->nest2_view_destroy( ).
        ms_control-client->nest2_view_display( val            = lo_view_detail->stringify( )
                                               id             = mcu->id-under_header " hier muss die ID stehen, die vorher vergeben wurde!
                                               method_insert  = 'addEndColumnPage'
                                               method_destroy = 'removeAllEndColumnPages' ).
      ENDIF.

    ENDIF.
  ENDMETHOD.

  METHOD do_display_navigation.
    IF ms_params-tree = abap_true.
*      IF mv_stringify = abap_true.

      DATA(lo_first) = io_flexible_column_layout->begin_column_pages( ).

      mo_ui_tree_mt->/sct/qp_if_ui_app~display( io_view   = lo_first
                                                io_client = ms_control-client ).

      RETURN.
*      ENDIF.
    ENDIF.

*    IF sy-uname = 'TROMFRA'.
    " Verbesserte Logik
    " Wenn Selektionsbedingungen geändert werden sollte ein view_model_update( ) ausreichend sein

    IF ms_globals-layout = mcu->sap-f-layouttype-endfullscreen
    OR ms_globals-layout = mcu->sap-f-layouttype-midfullscreen.
      RETURN.
    ENDIF.

* ROOT
    IF mv_stringify   = abap_true
    OR is_stateful( ) = abap_false.
      DATA(lo_root) = io_flexible_column_layout->begin_column_pages( ).

      mo_ui_objlist_root->/sct/qp_if_ui_app~display( io_view   = lo_root
                                                     io_client = ms_control-client ).

    ENDIF.
    ms_control-client->view_model_update( ).

* CHILD
    IF ms_globals-layout = mcu->sap-f-layouttype-threeendexpanded.

      IF abap_true = mo_ui_objlist_child->/sct/qp_if_ui_app~must_redraw_nested( )
      OR abap_true = mv_stringify.

        DATA(lo_child) = /sct/au5_cl_xml_view=>factory( ).

        mo_ui_objlist_child->/sct/qp_if_ui_app~display( io_view   = lo_child
                                                        io_client = ms_control-client ).

        ms_control-client->nest_view_display( val            = lo_child->stringify( )
                                              id             = mcu->id-under_header " hier muss die ID stehen, die vorher vergeben wurde!
                                              method_insert  = 'addMidColumnPage'
                                              method_destroy = 'removeAllMidColumnPages' ).

      ENDIF.

      ms_control-client->nest_view_model_update( ).

    ENDIF.
*      RETURN.
*    ENDIF.
*
*    DATA(lo_client) = CAST /sct/au5_cl_core_client( ms_control-client ).
*    IF lo_client->mo_action->ms_next-s_set-s_view-check_update_model = abap_true AND is_stateful( ) = abap_false.
*      "     IF sy-uname = 'TROMFRA'.
*      " * FT20260130 Test ohne kompletten Refresh
*      " * Wenn alle globalen Variablen sind bind_edit UND die Logik für die Aktualisierung der beiden Objeklisten sauber ist,
*      " * es gibt keine Notwendigkeit ein refresh zu machen
*      " * Kurz vor meime Urlaub will ich das aber nicht für alle umstellen.
*      "       DATA(hold_on) = 'at_breakpoint'.
*      "     ELSE.
*      /sct/qp_if_ui_root_app~set_stringify( ).
**      ENDIF.
*    ENDIF.
*
*    IF mv_stringify = abap_false
*    OR (    ms_globals-layout = mcu->sap-f-layouttype-endfullscreen
*         OR ms_globals-layout = mcu->sap-f-layouttype-midfullscreen ).
*      " Kein Navigationsbereich wird angezeigt und redraw nicht notwendig.
*      RETURN.
*    ENDIF.
*
*    IF mv_stringify = abap_true.
*
*      DATA(lo_split) = io_flexible_column_layout->begin_column_pages( ).
*
*      mo_ui_objlist_root->/sct/qp_if_ui_app~display( io_view   = lo_split
*                                                     io_client = ms_control-client ).
*
*    ENDIF.
*
*    IF is_stateful( ).
*      ms_control-client->view_model_update( ).
*    ENDIF.
*
*    IF ms_globals-layout = mcu->sap-f-layouttype-twomidexpanded.
*    " Kein objlist_child notwendig
*    ELSE.
*      IF is_stateful( ).
*        ms_control-client->nest_view_model_update( ).
*      ENDIF.
*
*      IF  abap_false = mo_ui_objlist_child->/sct/qp_if_ui_app~must_redraw_nested( )
*      AND abap_false = mv_stringify.
*        RETURN.
*      ENDIF.
*      DATA(lo_view_child) = /sct/au5_cl_xml_view=>factory( t_ns = VALUE #( ( n = 'id'
*                                                                             v = 'CHILD_VIEW' ) ) ).
*      mo_ui_objlist_child->/sct/qp_if_ui_app~display( io_view   = lo_view_child
*                                                      io_client = ms_control-client ).
*
*      ms_control-client->nest_view_display( val            = lo_view_child->stringify( )
*                                            id             = mcu->id-under_header " hier muss die ID stehen, die vorher vergeben wurde!
*                                            method_insert  = 'addMidColumnPage'
*                                            method_destroy = 'removeAllMidColumnPages' ).
*
*    ENDIF.
  ENDMETHOD.

  METHOD /sct/qp_if_ui_app~process_fcode.
*    CLEAR /sct/qp_if_ui_root_app~mt_next_events.
    rv_processed = super->/sct/qp_if_ui_app~process_fcode( is_get    = is_get
                                                           io_client = io_client ).

    DATA(i) = 0.
    " Wir ein Event prozessiert, können die sub-Apps weitere Events triggern
    " z.B do_jump triggert show_data
    " Alle Events werden in der Reihenfolge abgearbeitet, erst dann erfolgt die Anzeige
    LOOP AT /sct/qp_if_ui_root_app~mt_next_events ASSIGNING FIELD-SYMBOL(<ls_get>).
      DATA(ls_get) = <ls_get>.
*      DATA(ls_get) = is_get.
*      ls_get-event = <ls_get>-event.
*      ls_get-t_event_arg = <ls_get>-t_event_arg.
*      ls_get-r_event_data = <ls_get>-r_event_data.
*      ls_get-t_comp_params = <ls_get>-t_comp_params.

      DELETE /sct/qp_if_ui_root_app~mt_next_events INDEX sy-tabix.

      i += 1.
      super->/sct/qp_if_ui_app~process_fcode( is_get    = ls_get
                                              io_client = io_client ).

      IF i > 10.
        " potentielles Problem hier.
        " 20260709 : aktuell sind nur 1 bis 2 Folgeaktionen vorgesehen
        "        BREAK-POINT.
        EXIT.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD /sct/qp_if_ui_root_app~callback.
    TRY.
        DATA(lo_prev) = ms_control-client->get_app( ms_control-client->get( )-s_draft-id_prev_app ).
        result = CAST /sct/qp_if_ui_callback( lo_prev )->get_callback_event( ).
*        ms_control-client->message_box_display( `Navigate back to main App` ).
      CATCH cx_root.
    ENDTRY.
  ENDMETHOD.

  METHOD /sct/qp_if_ui_root_app~set_next_event.
    DATA(lv_idx) = line_index( /sct/qp_if_ui_root_app~mt_next_events[ event       = is_event-event
                                                                      t_event_arg = is_event-t_event_arg ] ).
    IF lv_idx IS NOT INITIAL.
      DELETE /sct/qp_if_ui_root_app~mt_next_events INDEX lv_idx.
    ENDIF.
    INSERT is_event INTO TABLE /sct/qp_if_ui_root_app~mt_next_events.
  ENDMETHOD.

  METHOD do_js.
    " Diese Methode stellt zusätzlichen JS-Code (JS-Funktionen) zur Verfügung

    " FT20260218 mit _z2ui5( )->scrolling( setupdate = true ) kann Abap2ui5 selber die Scrollposition aktualisieren
    " Dafür muss in AU5_CL_APP_APP_JS auch die Funktion zum zurückschreiben der Scrollposition erweitert werden, um eine Suche mit Teil-ID zu erlauben.

*    CHECK ms_params-save_scroll = abap_true.

    ms_control-client->_event_client( |var theme = sap.ui.getCore().getConfiguration().getTheme();|
    && |sap.sctau5.oResponseEvent("GET_THEME", theme);| ).

    RETURN.

*    DATA(left_scroll) = |function setScrollRoot( idx ) \{ debugger;| && |\n| &&
*                        |var element = document.querySelector('[id*="ROOT-page-cont"]');| && |\n| &&
*                        |if (element) element.scrollTop = idx ;\};| && |\n|.
*    DATA(mid_scroll) = |function setScrollChild( idx ) \{| && |\n| &&
*                       |var element = document.querySelector('[id*="CHILD-page-cont"]');| && |\n| &&
*                       |if (element) element.scrollTop = idx ;\};| && |\n|.
*    DATA(right_scroll) = |function setScrollDetail( idx ) \{ debugger;| && |\n| &&
*                         |var element = document.querySelector('[id*="OPL-opwrapper"]');| && |\n| &&
*                         |if (element) element.scrollTop = idx ;\};| && |\n|.

    " Funktion für eine Scrollbar.
    " Es wird ein HTML-Element gesucht, dessen ID der Muster <sel> enthält.
    " wenn vorhanden, wird dann die Scrollposition auf <position> gesetzt,
    DATA(set_scroll) = |function setScroll( sel , position ) \{ | && |\n| &&
                       |var selector =  '[id*="' + sel + '"]'| && |\n| &&
                       |var element = document.querySelector(selector);| && |\n| &&
*                         |if (element) \{ element.scrollTop = position; console.log( element.id )\};\};| && |\n|.
                       |if (element) element.scrollTop = position;\};| && |\n|.

    " Allgmeine Funktion, die bis zu 3 Scrollbars manipulieren kann
    DATA(scroll_all) = |function scrollAll(n1,v1,n2,v2,n3,v3) \{ | && " debugger;| && |\n| &&
                       |if (n1) setScroll(n1, v1);| && |\n| &&
                       |if (n2) setScroll(n2, v2);| && |\n| &&
                       |if (n3) setScroll(n3, v3);| && |\n| &&
                       |\};| && |\n|.

    ms_control-parent_view->_generic( name = 'script'
*                                      ns   = 'html' )->_cc_plain_xml( left_scroll && mid_scroll && right_scroll ).
                                      ns   = 'html' )->_cc_plain_xml( set_scroll && scroll_all ).

    RETURN.

    " TODO ?
    " Liefert true wenn dark-mode in Windows bevorzugt.
    " In kombination mit der Automatische Dunkelmoduserkennung in FLP
    " kann man eventuell bestimmen, ob dunkel oder nicht
    " window.matchMedia('(prefers-color-scheme: dark)').matches;

    " Session Storage :
    " https://s4a.secat.de:1443/zabap2ui5?app_start=z2ui5_cl_demo_app_327
    " Damit kann man aus der Session storage lesen
    " ParamName
    " sessionStorage.setItem( 'Prefix-Name', `"xxxx"` ) <- Auf die `" achten damit es sauber ausgelesen werden kann

*    DATA(script) = |sap.ui.getCore().attachInit(function() | && ' {' &&
*                   |  var element = document.querySelector('[id*="opwrapper"]');| &&
*                   |  if (element) | &&
*                   |  sessionStorage.setItem('DetailScrollPos', document.getElementById( element.id ).scrollTop)| && '}' && | );|.
*
*    ms_control-parent_view->_generic( name = 'script'
*                                      ns   = 'html' )->_cc_plain_xml( script ).
  ENDMETHOD.

  METHOD init_scroll.
*    IF is_stateful( ).
*      CLEAR mt_scroll.
*      RETURN.
*    ENDIF.

    IF mt_scroll IS NOT INITIAL.
      RETURN.
    ENDIF.

    " in /SCT/AU5_CL_APP_APP_JS->get wird ist die Scrolling-Funktion erweitert worden
    " wenn einen direkten Zugriff document.getElementById() kein Erfolg hatte, wird zusätzlich
    " ein document.querySelector mit ein Teil der ID gemacht, das funktioniert selbst nach einem Redraw, wenn die IDs hochgezählt wurden,
    " weil ein Teil der ID fix bleibt.
    " Somit ist es möglich hier die aktuellen Scrollpositionen für diese HTML-Elementen zu bekommen

    INSERT VALUE #( n = 'ROOT-page-cont' ) INTO TABLE mt_scroll. " root list ohne selektion oben
    INSERT VALUE #( n = 'content-1' ) INTO TABLE mt_scroll. " root falls Selektion oben
    INSERT VALUE #( n = 'CHILD-page-cont' ) INTO TABLE mt_scroll. " Mittleren bereich
    INSERT VALUE #( n = 'OPL-opwrapper' ) INTO TABLE mt_scroll. " Details ObjectPageList
  ENDMETHOD.

  METHOD set_scrollpos_after_redraw.
    IF ms_globals-settings-save_scroll = abap_true.

      " Wenn mv_scrollupdate = abap_true, wird eine Art Flush gemacht: Alle screen-Elemente scheine aufgefrischt zu werden,
      " das Ermöglicht zwar, die Scrollposition wiederanzuwenden, aber es ist während der Eingabe ziemlich nervig->.
      " Das Kennzeichen muss nur gesetzt werden wenn es wirklich nitwendig ist, z.B:
      " 1) Wechseln Anzeige <-> Anderungsmodus.
      " 2) TBD
*      = ms_control-client->mo
      "$TODO
*      DATA(lo_core) = CAST /sct/au5_cl_core_client( ms_control-client ).
*      DATA(lv_state_switched) = lo_core->mo_action->ms_next-s_set-s_stateful-switched.
*      IF is_stateful( ) = abap_false OR lv_state_switched = abap_true.
*        mv_scrollupdate = abap_true.
*      ENDIF.
    ENDIF.

** die Abap2ui5 Methode follow_up_action() kann anscheinend nur eine JS Funktion aufrufen,
** deswegen gibt es hier eine einzige scrollAll( ) Funktion, die bis zu 3 scrollbars setzen kann
** siehe Definition in do_js( ).
*
*    CHECK ms_params-save_scroll = abap_true.
**    check is_stateful( ) = abap_false.
*
*    DATA(lv_js) = ||.
*
** Jeder Eintrag repräsentiert eine Scrollbar :
** n = ID oder Teil der ID ( Suche des passenden Elementes mit querySelector )
** v = scroll-Position
*    LOOP AT mt_scroll ASSIGNING FIELD-SYMBOL(<scroll>).
*      IF <scroll>-v IS NOT INITIAL. "
*        IF lv_js IS INITIAL.
*          lv_js = |scrollAll( "{ <scroll>-n }", { CONV i( <scroll>-v ) }|.
*        ELSE.
*          lv_js = |{ lv_js },"{ <scroll>-n }", { CONV i( <scroll>-v ) }|.
*        ENDIF.
*      ENDIF.
*    ENDLOOP.
*
*    IF lv_js IS NOT INITIAL.
*      lv_js = |{ lv_js });|.
*      ms_control-client->follow_up_action( val = lv_js ).
*    ENDIF.
  ENDMETHOD.

  METHOD do_settings.
    DATA(view) = /sct/au5_cl_xml_view=>factory_popup( ).
    DATA(lo_vbox) = view->popover( placement  = `Bottom`
                                   afterclose = _event( 'CLOSE_SETTINGS' )
                                   title      = mutx->get_gui_text( mutx->n110 )
                                                )->vbox( ).

    " Damit die Werte in Statless mode überleben können, muss die standard _bind Methoden benutzt werden

    " Max Anz Knoten
    lo_vbox->hbox( )->label( class = `sapUiTinyMargin`
                             text  = mutx->get_text( mutx->u011 )
*                   )->input( value       = _bind( iv_edit = abap_true ir_data = REF #( ms_globals-select-max_sel_count ) )
                   )->input( value       = ms_control-client->_bind( ms_globals-settings-max_sel_count )
                             placeholder = 'Enter something here' ).

    " Anzeige graphische Hierarchie
    lo_vbox->hbox( )->switch( state = ms_control-client->_bind( ms_globals-settings-graph_hierarchy )
                   )->label( class = `sapUiTinyMargin`
                             text  = mutx->get_gui_text( mutx->n111 ) ).
*                  )->switch( state   = _bind( iv_edit = abap_true iv_name = 'GH' ir_data = REF #( ms_globals-graph_hierarchy ) )

    " App state
    lo_vbox->hbox( )->switch( state = ms_control-client->_bind( ms_globals-settings-disp_app_state )
                   )->label( class = `sapUiTinyMargin`
                             text  = mutx->get_gui_text( mutx->n115 ) ).

    " Scroll Position speichern
    lo_vbox->hbox( )->switch( state = ms_control-client->_bind( ms_globals-settings-save_scroll )
                   )->label( class = `sapUiTinyMargin`
                             text  = mutx->get_gui_text( mutx->n112 ) ).

*    " Display selected node on the top of the object list
*    lo_vbox->hbox( )->switch( state = ms_control-client->_bind_edit( ms_globals-settings-selected_on_top )
*                   )->label( class = `sapUiTinyMargin`
*                             text  = mutx->get_gui_text( mutx->n116 ) ).

    ms_control-client->popover_display( xml   = view->stringify( )
                                        by_id = id ).

    ms_control-root_app->popover_open( space ). " Wird close_event mitgegeben, dann erfolgt keine FCODE Bearbeitung iv_close_event = 'CLOSE_SETTINGS' ).
  ENDMETHOD.

  METHOD /sct/qp_if_ui_root_app~get_settings.
    result = ms_globals-settings.
  ENDMETHOD.

  METHOD /sct/qp_if_ui_root_app~get_data.
    rv_data = VALUE #( ms_globals-data[ n = iv_key ]-v OPTIONAL ).
  ENDMETHOD.

  METHOD /sct/qp_if_ui_root_app~set_data.
    DATA(lr_data) = REF #( ms_globals-data[ n = iv_key ] OPTIONAL ).
    IF lr_data IS BOUND.
      lr_data->v = iv_data.
    ELSE.
      INSERT VALUE #( n = iv_key
                      v = iv_data ) INTO TABLE ms_globals-data.
    ENDIF.
  ENDMETHOD.

  METHOD do_info.
    DATA(view) = /sct/au5_cl_xml_view=>factory_popup( ).
    " TODO: variable is assigned but only used in commented-out code (ABAP cleaner)
    DATA(lo_vbox) = view->popover( placement  = `Right`
                                   afterclose = _event( 'CLOSE_INFO' )
                                   title      = mutx->get_text( mutx->u001 ) " AppName
                                  )->vbox( ).

    "$TODO
*    " AppVersion
*    lo_vbox->label( class = `sapUiTinyMargin`
*                    text  = |{ mtx->get_text( mtx->hve ) } { /sct/au5_if_app~app_version }| ).

*    " Link zu QPPD.info
*    DATA(lv_text) = /sct/au5_if_app~app_link+8.
*    lo_vbox->link( class  = `sapUiTinyMarginBeginEnd`
*                   text   = lv_text
*                   href   = /sct/au5_if_app~app_link
*                   target = `_blank`
*                   icon   = `sap-icon://education`
**                   emphasized = 'true'
*                    ).
*
*    " Link zu Secat.de
*    lo_vbox->link( class  = `sapUiTinyMargin`
*                   text   = /sct/au5_if_app~author
*                   href   = /sct/au5_if_app~origin
*                   target = `_blank`
*                   icon   = `sap-icon://globe`
**                   emphasized = 'true'
*                    ).

    ms_control-client->popover_display( xml   = view->stringify( )
                                        by_id = id ).

    ms_control-root_app->popover_open( 'CLOSE_INFO' ). " Wird close_event mitgegeben, dann erfolgt keine FCODE Bearbeitung ).
  ENDMETHOD.

  METHOD get_selection_embedded.
    CLEAR: ms_globals-context-embedded,
           ms_globals-context-profile.

    IF cs_get-check_launchpad_active = abap_true.
      LOOP AT cs_get-t_comp_params ASSIGNING FIELD-SYMBOL(<param>)
           WHERE n CS 'embedded'.
        ms_globals-context-embedded = abap_true.
        IF <param>-n NS 'SalesOrder'.
          CONTINUE.
        ENDIF.

        DATA(lv_vbeln) = CONV vbeln( <param>-v ).

        lv_vbeln = |{ lv_vbeln ALPHA = IN }|.
*        CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT' EXPORTING input  = <param>-v
*                                                    IMPORTING output = lv_vbeln.

        IF lv_vbeln IS INITIAL.
          CONTINUE.
        ENDIF.

        SELECT 'I'  AS sign,
               'EQ' AS option,
               guid AS low
          FROM /sct/qp_c_ecc
          WHERE ( doctype = 'VBAP' OR doctype = 'VBAK' OR doctype = 'VBEP' ) AND vbeln = @lv_vbeln
          INTO TABLE @result.

* Geht nicht
*        ASSIGN ('(SAPMV45A)T180-TRTYP') TO FIELD-SYMBOL(<ls_trtyp>).
*
*        IF sy-subrc = 0.
*
*          CASE <ls_trtyp>.
*            WHEN 'B' OR 'H' OR 'V'. " Bearbeiten, Hinzufügen, Verarbeiten
*              ms_ecc-edit_mode = abap_true.
*
*            WHEN OTHERS.
*              ms_ecc-edit_mode = abap_false.
*
*          ENDCASE.
*        ENDIF.

      ENDLOOP.

    ELSE.
      SPLIT cs_get-s_config-search AT 'EMBEDDED' INTO DATA(lv_part1) DATA(lv_part2).
      IF lv_part2 IS NOT INITIAL.

        ms_globals-context-embedded = abap_true.
        SPLIT cs_get-s_config-search AT 'SALESORDER=' INTO lv_part1 lv_part2.
        IF lv_part2 IS NOT INITIAL.
          SPLIT lv_part2 AT '&' INTO lv_vbeln lv_part2.

          lv_vbeln = |{ lv_vbeln ALPHA = IN }|.
*          CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT' EXPORTING input  = lv_vbeln
*                                                      IMPORTING output = lv_vbeln.
          IF lv_vbeln IS NOT INITIAL.

            SELECT 'I'  AS sign,
                   'EQ' AS option,
                   guid AS low
              FROM /sct/qp_c_ecc
              WHERE ( doctype = 'VBAP' OR doctype = 'VBAK' OR doctype = 'VBEP' ) AND vbeln = @lv_vbeln
              INTO TABLE @result.

            MODIFY ENTITIES OF i_salesordertp
                   ENTITY salesorder
                   UPDATE
                   FIELDS ( purchaseorderbycustomer )
                   WITH VALUE #( ( PurchaseOrderByCustomer = |test Change FT{ cl_abap_context_info=>get_system_time( ) }|
                                   %key-salesorder         = lv_vbeln ) )
                   FAILED   DATA(ls_failed)
                   " TODO: variable is assigned but never used (ABAP cleaner)
                   REPORTED DATA(ls_reported).

            IF ls_failed IS INITIAL.
              " Display Mode
              ms_globals-context-embed_edit = abap_false.
              set_stateful( abap_false ).
            ELSE.
              " Edit Mode
              ms_globals-context-embed_edit = abap_true.
              set_stateful( ).
            ENDIF.

*            READ ENTITIES OF i_salesordertp
*                 ENTITY salesorder
*                 ALL FIELDS
*                 WITH VALUE #( ( salesorder = lv_vbeln ) )
*                 RESULT DATA(lt_so)
*                 FAILED data(nok).
*
*            " TODO: variable is assigned but never used (ABAP cleaner)
*            LOOP AT lt_so ASSIGNING FIELD-SYMBOL(<so>).
*
*            ENDLOOP.

          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.

    IF ms_globals-context-embedded = abap_true.
      ms_globals-context-profile = mc->profile_external.
    ELSE.
      ms_globals-context-profile = mc->profile_default.
    ENDIF.
  ENDMETHOD.

  METHOD /sct/qp_if_ui_root_app~get_context.
    result = ms_globals-context.
  ENDMETHOD.

  METHOD /sct/qp_if_ui_app~actualize_bindings.
    _bind( iv_fieldname = 'ms_globals-layout' ).
    LOOP AT mt_sub_app ASSIGNING FIELD-SYMBOL(<sub_app>).
      <sub_app>-app->actualize_bindings( ).
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
