CLASS /sct/qp_cl_ui_node DEFINITION
  PUBLIC
  INHERITING FROM /sct/qp_cl_ui_app
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES /sct/qp_if_ui_node.
    INTERFACES if_serializable_object.

    TYPES:
      BEGIN OF ty_action,
        action TYPE string,
        text   TYPE string,
        icon   TYPE string,
      END OF ty_action.

    DATA:
      BEGIN OF ms_fullscreen,
        fs    TYPE abap_bool,
        icon  TYPE string,
        event TYPE string,
      END OF ms_fullscreen.
    DATA ms_status TYPE /sct/qp_if_ui_app=>ty_s_status_display.
    DATA:
      BEGIN OF ms_headerdata,
        title TYPE string,
        vtext TYPE string,
      END OF ms_headerdata.
    DATA mt_actions  TYPE STANDARD TABLE OF ty_action WITH DEFAULT KEY.
    DATA mt_save_arg TYPE string_table.

    METHODS constructor.

    METHODS /sct/qp_if_ui_app~actualize_bindings REDEFINITION.
    METHODS /sct/qp_if_ui_app~display            REDEFINITION.
    METHODS /sct/qp_if_ui_app~init               REDEFINITION.
    METHODS /sct/qp_if_ui_app~must_redraw_nested REDEFINITION.

  PROTECTED SECTION.
    DATA mo_ui_header      TYPE REF TO /sct/qp_if_ui_header.
    DATA mv_display_footer TYPE abap_bool.
    DATA mv_stringify      TYPE abap_bool. " Die nested Seite, die dieses Objekt repräsentiert, muss komplett neuaufgebaut werden
    DATA mo_ui_log         TYPE REF TO /sct/qp_cl_ui_log.

    METHODS get_action IMPORTING is_get        TYPE /sct/au5_if_client=>ty_s_get  " AD, 2026.10.09, changed
                       RETURNING VALUE(result) TYPE /sct/qp_action.

    METHODS get_activity IMPORTING is_get        TYPE /sct/au5_if_client=>ty_s_get  " AD, 2026.10.09, changed
                         RETURNING VALUE(result) TYPE j_vorgang.

    METHODS do_check_changes     RETURNING VALUE(result)  TYPE abap_bool.
    METHODS do_footer.
    METHODS do_refresh_navigation.
    METHODS do_show_data.
    METHODS init_objtyp          RAISING   /sct/qp_cx_error.
    METHODS do_create_buttons    IMPORTING io_parent_view TYPE REF TO /sct/au5_cl_xml_view.

    METHODS do_process_fcode_sub REDEFINITION.
    METHODS process_fcode_self   REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.



CLASS /SCT/QP_CL_UI_NODE IMPLEMENTATION.


  METHOD constructor.
    " --------------------------------------------------------------------*
    " Änderungslog
    " --------------------------------------------------------------------*
    " AD, 2025.06.18, NOTE-3592, angelegt
    " --------------------------------------------------------------------*
    super->constructor( ).

    /sct/qp_cl_factory=>get_instance( CHANGING co_instance = mo_ui_handler ).
  ENDMETHOD.


  METHOD /sct/qp_if_ui_app~init.
    " --------------------------------------------------------------------*
    " Änderungslog
    " --------------------------------------------------------------------*
    " AD, 2025.06.26, NOTE-3592, angelegt
    " --------------------------------------------------------------------*

    " Init läuft immer ( um z.B ROOT-App zu aktualisieren)
    " die Base muss aber überleben können.
    DATA(lr_base) = ms_control-base.
    super->/sct/qp_if_ui_app~init( is_control = is_control ).

    IF ms_control-base IS INITIAL.
      ms_control-base = lr_base.
    ENDIF.
    IF ms_control-base IS BOUND.
      ms_control-id = |{ ms_control-base->guid } { mcu->id-node }|.
    ENDIF.
  ENDMETHOD.


  METHOD process_fcode_self.
    "--------------------------------------------------------------------"
    " Änderungslog
    "--------------------------------------------------------------------"
    " AD, 2025.06.25, NOTE-3592, angelegt
    "--------------------------------------------------------------------"
    " AD, 2026.02.26, NOTE-3693
    " SET_CHANGE_MODE aufrufen
    "--------------------------------------------------------------------"

    mv_stringify = abap_false. " Kompletten Redraw notwendig ?
    " BASE aus Argumenten ermitteln, eventuell Nachladen mit Objekttypdaten

    IF  ( is_get-event = mcu->events-workmode_display OR is_get-event = mcu->events-save )
    AND is_get-t_event_arg IS INITIAL.
      " Footer aktionen werden auf dem aktuellen Knoten ausgeführt,
      " nicht aus den ID in is_get-t_event_arg.

      " Aktionen aus dem OBJLIST-Popover werden mit Parameter verarbeitet.
      IF ms_control-base IS INITIAL.
        RETURN.
      ENDIF.

    ELSE.
      DATA(lr_new_base) = get_parameter_base_ref( is_get  = is_get
                                                  iv_full = abap_true ).
      IF lr_new_base IS INITIAL.
        RETURN.
      ENDIF.

      IF ms_control-base IS NOT BOUND
      OR ( ms_control-base IS BOUND AND lr_new_base->guid <> ms_control-base->guid ).
*      or is_stateful( ) = abap_false.
        " Neue Selektion
        " TODO: variable is assigned but never used (ABAP cleaner)
        DATA(lv_changed) = do_check_changes( ).
        CLEAR mt_sub_app.

*        CLEAR ms_control-root_app->ms_appdata-sub.
*        DELETE ms_control-root_app->mt_refs WHERE path CS 'MS_APPDATA-SUB-'.
      ENDIF.

      IF ms_control-base IS NOT BOUND OR ms_control-base->guid <> lr_new_base->guid.
        DATA(lv_base_was_changed) = abap_true.
      ENDIF.
      ms_control-base = lr_new_base.

    ENDIF.

*data(lv_act_event) = is_get-event.

    mt_def_arg = VALUE #( ( CONV #( ms_control-base->oguid ) )
                          ( CONV #( ms_control-base->guid ) )
*                          ( `${getScroll()}` )  "Versuch, die Scrollposition als Argument mitzugeben, kommt leider immer "null" zurück
                        ).

    IF is_stateful( ) = abap_false AND mt_def_arg = mt_save_arg.
      " Im Stateless Modus werden die BASE-Einträge immer neu geladen( ms_control-base bleibt nie gebunden )
      " Solange der gleichen Knoten angezeigt wird ( mt_def_arg = mt_save_arg ) ist kein Redraw notwendig
      lv_base_was_changed = abap_false.
    ENDIF.

    DATA(ls_context) = ms_control-root_app->get_context( ).
    " Edit Button sollte nicht sichtbar sein
    " Kein Footer.
    " Editierbarkeit anhand  ls_context-embed_edit
    IF ls_context-embedded = abap_true AND is_get-event = mcu->events-show_data.
      " Workmode ggfs ändern.
      IF ms_control-base->workmode = mc->workmode_display AND ls_context-embed_edit = abap_true.
        " TODO: variable is assigned but only used in commented-out code (ABAP cleaner)
        DATA(lv_set_change) = abap_true.
        process_fcode_self( VALUE #( BASE is_get
                                     event = mcu->events-workmode_change ) ).
      ENDIF.
      IF ms_control-base->workmode <> mc->workmode_display AND ls_context-embed_edit = abap_false.
        " TODO: variable is assigned but only used in commented-out code (ABAP cleaner)
        DATA(lv_set_display) = abap_true.
        process_fcode_self( VALUE #( BASE is_get
                                     event = mcu->events-workmode_display ) ).
      ENDIF.

    ENDIF.

    mt_save_arg = mt_def_arg.
    IF is_get-event = mcu->events-show_data.
      rv_processed = abap_true.

    ELSEIF is_get-event = mcu->events-toggle_detail_fs.
      IF ms_fullscreen-fs = abap_true.
        ms_fullscreen-fs = abap_false.
      ELSE.
        ms_fullscreen-fs = abap_true.
      ENDIF.
      rv_processed = abap_true.

    " Alle BUS-Aktionen
    ELSEIF is_get-event = mcu->events-workmode_change
        OR is_get-event = mcu->events-workmode_display
        OR is_get-event = mcu->events-save
        OR is_get-event = mcu->events-builder
        OR ( strlen( is_get-event ) >= 7 AND is_get-event(7) = 'ACTION_' )
        OR ( strlen( is_get-event ) >= 7 AND is_get-event(7) = 'STATUS_' ).

      DATA(lv_action) = get_action( is_get ).

      " BASE merken
      DATA(ls_base_before) = ms_control-base->*.

      rv_processed = abap_true.

      IF ms_control-base->guid IS NOT INITIAL.
        DATA(lv_save_stateful) = is_stateful( ).
        CASE lv_action.
          WHEN mcu->events-builder.
            " BUS aufrufen
            mo_bus->change( EXPORTING is_header  = VALUE #( guid = ms_control-base->guid )
                                      iv_builder = abap_true
                            IMPORTING et_return  = DATA(lt_return)
                                      ev_error   = DATA(lv_error) ).
            do_refresh_navigation( ).
            mv_stringify = abap_true.
            set_stateful( ).

          WHEN mcu->events-workmode_change.
            " BASE merken
            DATA(ls_base_display) = ms_control-base->*. " AD, 2026.03.06, NOTE-3693, inserted

            " BUS aufrufen
            mo_bus->workmode_change( EXPORTING is_header = VALUE #( guid = ms_control-base->guid )
                                     IMPORTING et_return = lt_return
                                               ev_error  = lv_error ).

            " AD, 2026.03.06, NOTE-3693, BoI
            " War vorher gesetzt?
            IF ls_base_display IS NOT INITIAL.
              " Referenz wiederfinden.
              IF ls_base_display-relattyp = mc->relattyp_space.
                " Das Nachladen zerstört die Referenz
                " Ohne PARENT_GUID suchen
                mo_controller->get_mod_base( EXPORTING iv_guid     = ls_base_display-guid
                                                       iv_relattyp = ls_base_display-relattyp
                                             " TODO: variable is assigned but only used in commented-out code (ABAP cleaner)
                                             IMPORTING er_base     = DATA(lr_base_display) ).
              ELSE.
                " Das Nachladen zerstört die Referenz
                mo_controller->get_mod_base( EXPORTING iv_parent_guid = ls_base_display-parent_guid
                                                       iv_guid        = ls_base_display-guid
                                                       iv_relattyp    = ls_base_display-relattyp
                                             IMPORTING er_base        = lr_base_display ).
              ENDIF.

              " Entgegen MVC (!) muss hier der Knoteninstanz mitgeteilt werden, dass der VIEW (!) jetzt im EDIT- bzw. DISPLAY-MODUS zu laufen hat
*              lr_base_display->instance->set_change_mode( lr_base_display ).
            ENDIF.
            " AD, 2026.03.06, NOTE-3693, EoI
            do_refresh_navigation( ).
            mv_stringify = abap_true.
            set_stateful( ).

          WHEN mcu->events-workmode_display.
            IF      mo_controller->get_changed_status( iv_root_guid = ms_control-base->root_guid ) IS NOT INITIAL
            AND NOT line_exists( is_get-t_event_arg[ table_line = `FORCE_DISPLAY` ] ).

              DATA(lr_base_oguid) = mo_ui_handler->get_base( iv_guid     = ms_control-base->root_guid
                                                             iv_oguid    = ms_control-base->root_guid
                                                             iv_stateful = is_stateful( ) ).
              DATA(ls_callback_event) = is_get.
              ls_callback_event-t_event_arg = VALUE #( BASE mt_def_arg
                                                       ( `FORCE_DISPLAY` ) ).

              DATA(lo_popup) = /sct/qp_cl_ui_popup=>factory(
                                   i_title               = |{ mutx->get_text( mutx->n100 ) }|
                                   i_text                = |{ get_node_objtext( lr_base_oguid ) }{ cl_abap_char_utilities=>cr_lf }{ cl_abap_char_utilities=>cr_lf }{ mutx->get_text( mutx->n101 ) }|
                                   i_button_text_confirm = mutx->get_text( mutx->n102 )
                                   i_button_text_cancel  = mutx->get_text( mutx->n103 )
                                   is_callback_event     = ls_callback_event ).
              ms_control-client->nav_app_call( lo_popup ).
              RETURN.

            ENDIF.
            " BUS aufrufen
            mo_bus->workmode_display( EXPORTING is_header = VALUE #( guid = ms_control-base->guid )
                                      IMPORTING et_return = lt_return
                                                ev_error  = lv_error  ).

            do_refresh_navigation( ).
            set_stateful( abap_false ).

          WHEN mcu->events-save.
            do_check_changes( ).
            " BUS aufrufen
            mo_bus->save( EXPORTING iv_commit_work = abap_true
                                    iv_root_guid   = ms_control-base->root_guid
                          IMPORTING et_return      = lt_return
                                    ev_error       = lv_error ).
            mo_bus->workmode_display( EXPORTING is_base  = ms_control-base->*
                                      " TODO: variable is assigned but never used (ABAP cleaner)
                                      IMPORTING ev_error = DATA(lv_error2) ). " Fehler aufgetreten
            " Base neuladen
            CLEAR ms_control-base.
            do_refresh_navigation( ).
            mv_stringify = abap_true.
            set_stateful( abap_false ).

          WHEN OTHERS.
            IF is_get-event(7) = 'STATUS_'.
              DATA(lv_activity) = get_activity( is_get ).

              " BUS setzt automatisch Workmode C, was hier nicht gewollt ist ( embedded, workmode S)
              " Controller bzw Model direkt aufrufen.

*              mo_bus->activity( EXPORTING is_header   = ms_control-base->root_instance->ms_node_data
*                                          iv_activity = lv_activity
*                                          it_change   = VALUE #( ( ms_control-base->instance->ms_node_data ) )
*                                IMPORTING et_return   = lt_return
*                                          ev_error    = lv_error ).
              TRY.
                  mo_controller->mo_model->is_base_status_changeable( ir_base = ms_control-base ).

                  IF abap_false = mo_controller->mo_model->is_base_action_allowed( iv_action = lv_action
                                                                                   ir_base   = ms_control-base ).

                    RAISE EXCEPTION TYPE /sct/qp_cx_error EXPORTING textid = mx->activity_not_allowed.

                  ENDIF.

                  mo_controller->do_mod_node_activity( iv_action = CONV #( |{ is_get-event(7) }{ lv_activity }| )
                                                       is_base   = ms_control-base->* ).

                  set_stateful( ).

                CATCH /sct/qp_cx_error INTO DATA(lo_err).

                  do_show_message( it_return  = VALUE #( ( lo_err->get_msg_bapiret( ) ) )
                                   iv_msgtype = /sct/qp_cl_const=>msgtype_e ).

              ENDTRY.

              do_refresh_navigation( ).
              mv_stringify = abap_true.

            ELSE.
              rv_processed = abap_false.
            ENDIF.
        ENDCASE.

        " Fehler?
        IF lv_error IS NOT INITIAL.
          " Fehlernachricht ausgeben
          do_show_message( it_return  = lt_return
                           iv_msgtype = mc->msgtype_e ).
          ms_control-root_app->set_stringify( ).
          " TODO ggfs stateful zurücksetzen ?

          IF is_stateful( ) <> lv_save_stateful AND NOT line_exists( lt_return[ number = 143 ] ).
            " Die Aktion ist fehlegeschlagen ( lv_error = abap_true ) UND
            " es wurde kein Success gemeldet ( Der BUS wirft error = X auch wenn die Aktion erfolgreich war, weil die Daten ggfs fehlerhaft sind )
            " Dann wird der state wieder zurückgedreht
**            BREAK-POINT.
            set_stateful( lv_save_stateful ).
          ENDIF.

        ENDIF.

        " BASE wiederfinden,(Stateful/stateless), falls notwendig
        DATA(lr_base) = mo_ui_handler->get_base( iv_oguid    = ls_base_before-oguid
                                                 iv_guid     = ls_base_before-guid
                                                 iv_stateful = is_stateful( ) ).

        IF ms_control-base           IS NOT BOUND
        OR ms_control-base->instance <> lr_base->instance.
* Der Vergleich mit key ist nicht ausreichend: wenn ein ROOT-Knoten von Stateless in Stateful-Zustand geändert wird bleibt key identisch
*        OR ms_control-base->key <> lr_base->key.
          lv_base_was_changed = abap_true.
          ms_control-base = lr_base.
          CLEAR mt_sub_app.
        ENDIF.
        rv_processed = abap_true.
      ENDIF.

    ELSE.
      rv_processed = abap_false.
    ENDIF.

    IF lv_base_was_changed = abap_true.
      mv_stringify = abap_true.
    ENDIF.

    IF ms_control-base IS NOT BOUND.
      " Nachladen eines Objektes mit Workmode A -> keine BASE vorhanden
      RETURN.
    ENDIF.
    IF ms_control-base->workmode <> mc->workmode_display.
      ms_control-base->instance->set_change_mode( ms_control-base ).
    ENDIF.

    IF mt_sub_app IS INITIAL. " Die Base hat sich geändert, die Objekttypen müssen neuinitialisiert werden
      init_objtyp( ).
      /sct/qp_if_ui_app~actualize_bindings( ).
    ENDIF.

*    IF lv_set_change = abap_true.
*
*    ENDIF.
*    IF lv_set_display = abap_true.
*
*    ENDIF.

    do_footer( ).
  ENDMETHOD.


  METHOD do_create_buttons.
    " --------------------------------------------------------------------*
    " Änderungslog
    " --------------------------------------------------------------------*
    " AD, 2025.07.09, NOTE-3592, angelegt
    " --------------------------------------------------------------------*

    DATA(lo_actions) = io_parent_view->_generic( ns   = 'uxap'
                                                 name = 'actions' ).

    " Das Profil hat eine höhere Prioriät als die TOOGLE-Actioncodes oben.
    DATA(lt_excl) = ms_control-base->excl_action.
    LOOP AT mo_controller->get_excl_actions_prof( iv_workmode = ms_control-base->workmode
                                                  iv_app      = VALUE #( ) ) ASSIGNING FIELD-SYMBOL(<ls_excl_actions_prof>).
      INSERT <ls_excl_actions_prof> INTO TABLE lt_excl.
    ENDLOOP.

    IF NOT line_exists( lt_excl[ actioncode = mc->action_change  ] ).

      get_button( io_parent_view = lo_actions
                  iv_type        = mcu->sap-m-buttontype-emphasized "'Emphasized'
                  iv_text        = mutx->get_text( mutx->u019 ) " Bearbeiten
                  iv_icon        = 'sap-icon://edit'
                  iv_action      = mcu->events-workmode_change
                  it_arg         = mt_def_arg ).

    ENDIF.

    " *********************************************************************
    " Actions
    " *********************************************************************
    IF ms_control-base->workmode = mc->workmode_change.

      " An hier das MENÜ
      " TODO: variable is assigned but only used in commented-out code (ABAP cleaner)
      DATA(lo_menu_actions) = get_menu( io_parent_view = lo_actions
                                        iv_icon        = 'sap-icon://building'
                                        iv_type        = mcu->sap-m-buttontype-transparent "'Transparent'
                                        iv_text        = mutx->get_text( mutx->u050 )
                                        iv_items       = ms_control-client->_bind( mt_actions )

                                                                )->items(
                                                                )->menu_item( press = _event( iv_name = 'ACTION_'
                                                                                              it_arg  = VALUE #( BASE mt_def_arg
                                                                                                                 ( `${ACTION}` ) ) ) " so wird NAME leider nicht aufgelöst
                                                                              text  = `{TEXT}`
                                                                              icon  = `{ICON}`
                                                                           )->get_parent( ).

*
*      IF NOT line_exists( ms_control-base->excl_action[ actioncode = mc->action_builder  ] ).
*        get_menu_item( io_parent_view = lo_menu_actions
*                       iv_text        = mutx->get_text( mutx->u022 )  " Builder
*                       iv_icon        = 'sap-icon://building'
*                       iv_action      = mcu->events-builder
*                       it_arg         = mt_def_arg ).
*      ENDIF.
*
*      IF NOT line_exists( ms_control-base->excl_action[ actioncode = mc->action_globgenmon  ] ).
*
*        get_menu_item( io_parent_view = lo_menu_actions
*                       iv_text        = mutx->get_text( mutx->u023 ) " Generierung aktivieren
*                       iv_icon        = 'sap-icon://restart'
*                       iv_action      = mcu->events-builder
*                       it_arg         = mt_def_arg ).
*
*      ENDIF.
*
*      IF NOT line_exists( ms_control-base->excl_action[ actioncode = mc->action_globgenmoff  ] ).
*
*        get_menu_item( io_parent_view = lo_menu_actions
*                       iv_text        = mutx->get_text( mutx->u024 ) " Generierung deaktivieren
*                       iv_icon        = 'sap-icon://stop'
*                       iv_action      = mcu->events-glgenmoff
*                       it_arg         = mt_def_arg ).
*
*      ENDIF.
*
*      IF NOT line_exists( ms_control-base->excl_action[ actioncode = mc->action_delete  ] ).
*
*        get_menu_item( io_parent_view = lo_menu_actions
*                       iv_text        = mutx->get_text( mutx->u025 )  " Objekt löschen
*                       iv_icon        = 'sap-icon://delete'
*                       iv_action      = mcu->events-delete
*                       it_arg         = mt_def_arg ).
*
*      ENDIF.
*
*      IF NOT line_exists( ms_control-base->excl_action[ actioncode = mc->action_activate ] ).
*        get_menu_item( io_parent_view = lo_menu_actions
*                       iv_text        = mutx->get_text( mutx->u026 ) " Aktivieren
*                       iv_icon        = 'sap-icon://activate'
*                       iv_action      = mcu->events-activate
*                       it_arg         = mt_def_arg ).
*
*      ENDIF.
    ENDIF.

    " *********************************************************************
    " Aktivitäten
    " *********************************************************************

    " MenuButton mit Binding

* TEST FT20261019 Struktur binden, um anschließend auf die Komponenten zugreifen zu können geht  nicht
**    _bind(
**      EXPORTING
**        iv_edit      = abap_true
**        iv_fieldname = |ms_status|
**    ).
**
**
**
**
**    DATA(lo_menu_activities2) = get_menu( io_parent_view = lo_actions
**                                          iv_type        = ms_control-client->_bind( ms_status-type )
**
**                                          iv_icon        = ms_control-client->_bind( ms_status-icon )
**
**                                          iv_text        = ms_control-client->_bind( ms_status-text )
**
**                                          iv_items       = ms_control-client->_bind( ms_status-act )
**                                                                )->items(
*** Deswegen wird hier immer den gleichen Event abgesetzt ('STATUS_'), der richtige Vorgang steht dafür als 3. Parameter
**                                                                )->menu_item( press = _event( iv_name = 'STATUS_'
**                                                                                              it_arg  = VALUE #( BASE mt_def_arg
**                                                                                                                 ( `${VRGNG}` ) ) ) " so wird NAME leider nicht aufgelöst
**                                                                              text  = `{TXT}`
**                                                                              icon  = `{ICON_UI}`
**                                                                           )->get_parent( ).

    " TODO: variable is assigned but never used (ABAP cleaner)
    DATA(lo_menu_activities2) = get_menu( io_parent_view = lo_actions
                                          iv_type        = ms_control-client->_bind( ms_status-type )
*                                          ir_data        = REF #( ms_status-type )
*                                          iv_name        = 'NodeStatusType' )
                                          iv_icon        = ms_control-client->_bind( ms_status-icon )
*                                          ir_data        = REF #( ms_status-icon )
*                                          iv_name        = 'NoderStatusIcon' )
                                          iv_text        = ms_control-client->_bind( ms_status-text )
*                                          ir_data        = REF #( ms_status-text )
*                                          iv_name        = 'NodeStatusText' )
                                          iv_items       = ms_control-client->_bind( ms_status-act )
*                                          ir_data        = REF #( ms_status-act )
*                                          iv_name        = 'NodeActivities' )
                                                                )->items(
*                                                                )->menu_item( press = _event( `{NAME}` ) " so wird NAME leider nicht aufgelöst
* Deswegen wird hier immer den gleichen Event abgesetzt ('STATUS_'), der richtige Vorgang steht dafür als 3. Parameter
                                                                )->menu_item( press = _event( iv_name = 'STATUS_'
                                                                                              it_arg  = VALUE #( BASE mt_def_arg
                                                                                                                 ( `${VRGNG}` ) ) ) " so wird NAME leider nicht aufgelöst
                                                                              text  = `{TXT}`
                                                                              icon  = `{ICON_UI}`
                                                                           )->get_parent( ).

** Menubutton ohne Binding aber mit loop
**    DATA(lo_menu_activities) = get_menu( io_parent_view = lo_actions
**                                         iv_type        = _bind( iv_edit = is_stateful( )
**                                                                 ir_data = REF #( ms_status-type )
**                                                                 iv_name = 'NodeStatusType' )
**                                         iv_icon        = _bind( iv_edit = is_stateful( )
**                                                                 ir_data = REF #( ms_status-icon )
**                                                                 iv_name = 'NoderStatusIcon' )
**                                         iv_text        = _bind( iv_edit = is_stateful( )
**                                                                 ir_data = REF #( ms_status-text )
**                                                                 iv_name = 'NodeStatusText' ) ).
**
**    LOOP AT ms_status-act ASSIGNING FIELD-SYMBOL(<ls_activities>).
**      get_menu_item( io_parent_view = lo_menu_activities
**                     iv_text        = CONV #( <ls_activities>-txt )
**                     iv_icon        = <ls_activities>-icon_ui
**                     iv_action      = CONV #( <ls_activities>-name )
**                     ).
**    ENDLOOP.

    " *********************************************************************
    " LOG
    " *********************************************************************
    mo_ui_log->/sct/qp_if_ui_app~display( io_view   = lo_actions
                                          io_client = ms_control-client ).

    " *********************************************************************
    " FULLSCREEN
    " *********************************************************************

    IF ms_fullscreen-fs IS INITIAL.
      ms_fullscreen-icon = 'sap-icon://full-screen'.
    ELSE.
      ms_fullscreen-icon = 'sap-icon://exit-full-screen'.
    ENDIF.

    lo_actions->button( icon  = ms_control-client->_bind( ms_fullscreen-icon )

*                        iv_name = 'TOGGLE_FS_ICON'
*                        ir_data = REF #( ms_fullscreen-icon ) )
                        press = _event( mcu->events-toggle_detail_fs ) ).
  ENDMETHOD.


  METHOD do_show_data.
    " --------------------------------------------------------------------*
    " Änderungslog
    " --------------------------------------------------------------------*
    " AD, 2025.06.18, NOTE-3592, angelegt
    " --------------------------------------------------------------------*

    IF ms_control-base IS NOT BOUND.
      RETURN.
    ENDIF.

*    DATA(lo_view_nested) = ms_control-parent_view->page( ). "Test scrolling: bringt nichts
    DATA(lo_view_nested) = ms_control-parent_view.

    DATA(lo_page) = lo_view_nested->object_page_layout( "$TODO id                       = 'OPL'  " AD, 2026.10.09, changed
                                                        showtitleinheadercontent = abap_true
                                                        showeditheaderbutton     = abap_true
                                                        editheaderbuttonpress    = ms_control-client->_event( 'EDIT_HEADER_PRESS' )
                                                        uppercaseanchorbar       = abap_false ).

    " *********************************************************************
    " HEADER
    " *********************************************************************

    DATA(lv_ui_icon) = get_ui_icon( ms_control-base ).
    DATA(lo_header_title) = lo_page->header_title( )->object_page_dyn_header_title( ).

    DATA(lo_hbox_exp) = lo_header_title->expanded_heading( )->hbox( ).
    lo_hbox_exp->icon( src   = lv_ui_icon
                       class = 'sapUiSmallMarginEnd'
                       size  = '2rem' ).
    DATA(lo_hbox_vbox) = lo_hbox_exp->vbox( ). " VNAME und VTEXT untereinander
    lo_hbox_vbox->title( text     = ms_control-client->_bind( ms_headerdata-title )
                         wrapping = abap_true ).

    lo_hbox_vbox->label( text = ms_control-client->_bind( ms_headerdata-vtext ) ).
    DATA(lo_hbox_snapped) = lo_header_title->snapped_heading( )->hbox( ).
    lo_hbox_snapped->icon( src   = lv_ui_icon
                           class = 'sapUiSmallMarginEnd'
                           size  = '2rem' ).
    DATA(lo_hbox_s_vbox) = lo_hbox_snapped->vbox( ). " VNAME und VTEXT untereinander
    lo_hbox_s_vbox->title( text     = ms_control-client->_bind( ms_headerdata-title )
                           wrapping = abap_true ).

    lo_hbox_s_vbox->label( text = ms_control-client->_bind( ms_headerdata-vtext ) ).

    do_create_buttons( io_parent_view = lo_header_title ).

    DATA(lo_header_content) = lo_page->header_content( ns = 'uxap' ).

    " HEADER anzeigen
    mo_ui_header->/sct/qp_if_ui_app~display( io_view   = lo_header_content
                                             io_client = ms_control-client ).

    " *********************************************************************
    " Log message strips
    " *********************************************************************

    DATA(lt_log) = ms_control-base->instance->mo_log->get_messages( ).
    LOOP AT lt_log ASSIGNING FIELD-SYMBOL(<log>)
         WHERE ( msgty     = mc->msgtype_e      OR msgty     = mc->msgtype_a )
           AND ( objekttyp = mc->objekttyp_node OR objekttyp = mc->objekttyp_nodecheck ).
      lo_header_content->message_strip( text     = <log>-message
                                        type     = mcu->sap-ui-core-message-MessageType-error
                                        showicon = abap_true ).
    ENDLOOP.

    DATA(lo_sections) = lo_page->sections( ).

    " *********************************************************************
    " Hierachie nach unten als Objekttyp anzeigen
    " *********************************************************************

    IF  ms_control-base->instance->mt_childs                 IS NOT INITIAL
    AND ms_control-root_app->get_settings( )-graph_hierarchy  = abap_true.
      DATA(lo_sub) = lo_sections->object_page_section( titleuppercase = abap_false
                         )->heading( ns = `uxap`
                       )->get_parent(
                       )->sub_sections(
                           )->object_page_sub_section( title = mtx->get_text( 'HIE' )
                               )->blocks( ). "->vbox( id = |VBOX_Children| ).

      DATA lo_hiera TYPE REF TO /sct/qp_cl_ui_hiera.
      lo_hiera = NEW #( is_obj = VALUE /sct/qp_if_ui_objtyp=>ty_s_objtyp( objekttyp = 'HIERA'
                                                                          base      = ms_control-base ) ).

      lo_hiera->/sct/qp_if_ui_app~init( ms_control ).
      lo_hiera->/sct/qp_if_ui_app~actualize_bindings( ).
      lo_hiera->/sct/qp_if_ui_app~display( io_client = ms_control-client
                                           io_view   = lo_sub ).

    ENDIF.

    " *********************************************************************
    " Objekttypen
    " *********************************************************************

    ms_control-base->instance->get_node_objects( IMPORTING et_node_objects = DATA(lt_node_objects) ).

    LOOP AT /sct/qp_if_ui_app~mt_sub_app ASSIGNING FIELD-SYMBOL(<ls_sub_app>)
         WHERE app IS BOUND.
      ASSIGN lt_node_objects[ objekttyp = <ls_sub_app>-id ] TO FIELD-SYMBOL(<ls_node_objects>).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      DATA(lo_subsection) =
      lo_sections->object_page_section( titleuppercase = abap_false
                                        id             = |{ <ls_node_objects>-objekttyp }1|
                                        title          = |{ <ls_node_objects>-objekttyp }| " Fallback falls objekttyptext leer ist
          )->heading( ns = `uxap`
                      ")->message_strip( text = 'this is a message strip'
        )->get_parent(
        )->sub_sections(
            )->object_page_sub_section( id    = |{ <ls_node_objects>-objekttyp }|
                                        title = |{ <ls_node_objects>-objekttyptext }| " Hier steht der Titel, der angezeigt wird
                )->blocks( )->vbox( ). " id = |VBOX{ <ls_node_objects>-objekttyp }| ).

      TRY.
          " Dem Objekttyp die neue SUBSECTION mitteilen
          " Den Objekttypen prozessieren
          <ls_sub_app>-app->display( io_client = ms_control-client
                                     io_view   = lo_subsection ).
        CATCH cx_root INTO DATA(lo_err).
          " TODO: variable is assigned but never used (ABAP cleaner)
          DATA(text) = lo_err->get_text( ).
          " TODO: variable is assigned but never used (ABAP cleaner)
          DATA(ltext) = lo_err->get_longtext( ).
          BREAK-POINT.
      ENDTRY.

    ENDLOOP.

    IF mv_display_footer = abap_true.

      DATA(lo_footer) = ms_control-root_app->get_footer( ). " Diese Methode kann nur im PBO aufgerufen werden

      IF NOT line_exists( ms_control-base->excl_action[ actioncode = mc->action_save  ] ).
        get_footer_button( io_parent_view = lo_footer
                           iv_type        = mcu->sap-m-buttontype-emphasized "'Emphasized'
                           iv_text        = mutx->get_text( mutx->u027 ) " Sichern
                           iv_icon        = 'sap-icon://save'
                           iv_action      = mcu->events-save
                           it_arg         = VALUE #( ) ). " mt_def_arg ). Keine Arguments mitgeben

      ENDIF.

      IF NOT line_exists( ms_control-base->excl_action[ actioncode = mc->action_display  ] ).
        get_footer_button( io_parent_view = lo_footer
                           iv_type        = mcu->sap-m-buttontype-default "'Default' "'Reject'
                           iv_text        = mutx->get_text( mutx->u034 ) " Abbrechen
                           iv_icon        = 'sap-icon://sys-cancel'
                           iv_action      = mcu->events-workmode_display
                           it_arg         = VALUE #( ) ). " mt_def_arg ).

      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_app~display.
    ms_control-client      = io_client.
    ms_control-parent_view = io_view.

    do_show_data( ).
  ENDMETHOD.


  METHOD init_objtyp.
    " --------------------------------------------------------------------*
    " Änderungslog
    " --------------------------------------------------------------------*
    " FT20250714, NOTE-3592, angelegt
    " --------------------------------------------------------------------*

    IF ms_control-base IS INITIAL OR ms_control-base->vblock IS NOT INITIAL.
      RETURN.
    ENDIF.

    " Wenn die Objekttypen neuaufgebaut werden muss der globalen Datenbereich reinitialisiert werden
    ms_control-root_app->delete_sub_refs( ).


    " *********************************************************************
    " HEADER & LOG
    " *********************************************************************

    DATA(lv_headerclass) = ms_control-base->instance->mo_header->ms_node_object-objtypclass_ui.
    " Fallback
    IF ms_control-base->instance->mo_header->ms_node_object-objtypclass_ui IS INITIAL.
      lv_headerclass = '/SCT/QP_IF_UI_HEADER'.
    ENDIF.
    lv_headerclass = /sct/qp_cl_factory=>get_classname( iv_classname = lv_headerclass ).

    " TODO: variable is assigned but never used (ABAP cleaner)
    ASSIGN /sct/qp_if_ui_app~mt_sub_app[ id = 'HEADER' ] TO FIELD-SYMBOL(<ls_app>).
    IF sy-subrc <> 0.
      CREATE OBJECT mo_ui_header TYPE (lv_headerclass) EXPORTING is_obj = VALUE /sct/qp_if_ui_objtyp=>ty_s_objtyp( objekttyp = ms_control-base->instance->mo_header->ms_node_object-objekttyp
                                                                                                                   object    = ms_control-base->instance->mo_header
                                                                                                                   obj       = mo_ui_header
                                                                                                                   base      = ms_control-base ).

      DATA(lr_hdr) = do_insert_sub_app( is_sub_app = VALUE #( index = '0000'
                                                              id    = 'HEADER'
                                                              class = lv_headerclass
                                                              app   = mo_ui_header ) ).

    ENDIF.
    mo_ui_header->/sct/qp_if_ui_app~init( is_control = VALUE #( BASE ms_control
                                                                parent_app = me
                                                                aidx       = lr_hdr->aidx ) ).

    DATA(lv_logclass) = /sct/qp_cl_factory=>get_classname( iv_classname = '/SCT/QP_CL_UI_LOG' ).
    ASSIGN /sct/qp_if_ui_app~mt_sub_app[ id = 'LOG' ] TO <ls_app>.
    IF sy-subrc <> 0.
      CREATE OBJECT mo_ui_log TYPE (lv_logclass) EXPORTING is_obj = VALUE /sct/qp_if_ui_objtyp=>ty_s_objtyp( objekttyp = 'LOG'
                                                                                                             object    = ms_control-base->instance->mo_log
                                                                                                             obj       = mo_ui_log
                                                                                                             base      = ms_control-base ).
      DATA(lr_log) = do_insert_sub_app( is_sub_app = VALUE #( index = '9999'
                                                              id    = 'LOG'
                                                              class = lv_logclass
                                                              app   = mo_ui_log ) ).

    ENDIF.
    mo_ui_log->/sct/qp_if_ui_app~init( is_control = VALUE #( BASE ms_control
                                                             parent_app = me
                                                             aidx       = lr_log->aidx ) ).

    " *********************************************************************
    " Andere Objekttypen (Registerkarten)
    " *********************************************************************
    ms_control-base->instance->get_node_objects( IMPORTING et_node_objects = DATA(lt_node_objects) ).

    LOOP AT lt_node_objects ASSIGNING FIELD-SYMBOL(<ls_node_objects>) WHERE verwend  = mc->verwend_r
                                                                        AND techtyp <> mc->techtyp_sta AND techtyp <> mc->techtyp_adm.

      " Gibt es für diesen Objekttypen schon eine Instanz?
      DATA(lr_sub_app) = REF #( /sct/qp_if_ui_app~mt_sub_app[ id = <ls_node_objects>-objekttyp ] OPTIONAL ).
      IF lr_sub_app IS NOT BOUND.
        " Neuen Eintrag anlegen

        lr_sub_app = do_insert_sub_app( is_sub_app = VALUE #( index = <ls_node_objects>-sortnr
                                                              id    = <ls_node_objects>-objekttyp
                                                              class = <ls_node_objects>-objtypclass_ui ) ).

*        ms_control-root_app->ms_appdata-aidx += 1.
*        INSERT VALUE #( index = <ls_node_objects>-sortnr
*                        id    = <ls_node_objects>-objekttyp
*                        class = <ls_node_objects>-objtypclass_ui
*                        aidx  = ms_control-root_app->ms_appdata-aidx )
*               INTO TABLE /sct/qp_if_ui_app~mt_sub_app ASSIGNING <ls_sub_app>.
      ENDIF.

      " Fallback
      IF <ls_node_objects>-objtypclass_ui IS INITIAL AND ( <ls_node_objects>-techtyp = mc->techtyp_tme OR <ls_node_objects>-techtyp = mc->techtyp_pmk ).
        <ls_node_objects>-objtypclass_ui = '/SCT/QP_CL_UI_MAMBA'.
      ENDIF.

      IF <ls_node_objects>-objtypclass_ui IS INITIAL.
        CONTINUE.
      ENDIF.

      IF lr_sub_app->app IS NOT BOUND.
        " Instanz erstellen
        DATA(lv_uiclass) = /sct/qp_cl_factory=>get_classname( iv_classname = <ls_node_objects>-objtypclass_ui ).
        <ls_node_objects>-objtypclass_ui = lv_uiclass.
        lr_sub_app->class = <ls_node_objects>-objtypclass_ui.

        CREATE OBJECT lr_sub_app->app TYPE (lv_uiclass) EXPORTING is_obj = VALUE /sct/qp_if_ui_objtyp=>ty_s_objtyp( objekttyp = <ls_node_objects>-objekttyp
                                                                                                                    object    = <ls_node_objects>-object
                                                                                                                    obj       = lr_sub_app->app
                                                                                                                    base      = ms_control-base ).
      ENDIF.

      TRY.
          " Dem Objekttyp die neue SUBSECTION mitteilen
          lr_sub_app->app->init( is_control = VALUE #( BASE ms_control
                                                       parent_app = me
                                                       aidx       = lr_sub_app->aidx ) ).
        CATCH cx_root INTO DATA(lo_err).
          " TODO: variable is assigned but never used (ABAP cleaner)
          DATA(text) = lo_err->get_text( ).
          " TODO: variable is assigned but never used (ABAP cleaner)
          DATA(ltext) = lo_err->get_longtext( ).
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.


  METHOD do_refresh_navigation.
    ms_control-root_app->set_next_event( is_event = VALUE #( event       = mcu->events-nav_list_refresh
                                                             t_event_arg = mt_def_arg ) ).
*    ms_control-root_app->process_fcode( is_get    = VALUE #( event       = mcu->events-nav_list_refresh
*                                                             t_event_arg = mt_def_arg )
*                                        io_client = ms_control-client ).
  ENDMETHOD.


  METHOD do_footer.
    IF ms_control-root_app->get_context( )-embedded = abap_true.
      " Kein dediziertes Footer wenn die App embedded ist,
      mv_display_footer = abap_false.
      RETURN.
    ENDIF.

    DATA(lv_old_footer) = mv_display_footer.
    " Der angezeigte Knoten entscheidet, ob ein FOOTER angezeigt werden soll.
    mv_display_footer = abap_false.

    IF ms_control-base IS NOT INITIAL.
      IF (     NOT line_exists( ms_control-base->excl_action[ actioncode = mc->action_save ] )
           AND     ms_control-base->root_instance->ms_control-is_changed = abap_true )
      OR NOT line_exists( ms_control-base->excl_action[ actioncode = mc->action_display ] ).
        mv_display_footer = abap_true.
      ENDIF.
    ENDIF.

    IF lv_old_footer <> mv_display_footer.

*      DATA(lo_ui) = CAST /sct/qp_cl_ui( ms_control-root_app ).
*      lo_ui->ms_globals-footer_visible = mv_display_footer.

      " Footer wird neu angezeigt oder soll verschwinden -> stringify notwendig,
      ms_control-root_app->set_stringify( ).
    ENDIF.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_app~must_redraw_nested.
    " Der Knoten entscheidet, ein Redraw machen zu müssen
    result = mv_stringify.
    IF mv_stringify = abap_true.
      RETURN.
    ENDIF.
    LOOP AT mt_sub_app ASSIGNING FIELD-SYMBOL(<sub>)
         WHERE app IS BOUND.
      " Jedes Objekttyp kann auch die Eintscheidung treffen
      IF <sub>-app->must_redraw_nested( ) = abap_true.
        result = abap_true.
        EXIT.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD do_check_changes.
    IF is_stateful( ) = abap_false.
      RETURN.
    ENDIF.

    IF ms_control-base IS NOT BOUND OR ms_control-base->workmode = mc->workmode_display.
      RETURN.
    ENDIF.

    LOOP AT mt_sub_app ASSIGNING FIELD-SYMBOL(<ls_sub_app>)
         WHERE app IS BOUND.
      TRY.
          DATA(lv_result) = <ls_sub_app>-app->check_changes( ).
          " abap_true: Objekttyp ist geändert worden
          " abap_false: Objekttyp ist NICHT geändert worden
          " abap_undefined: nicht sicher ( es gab Änderungen, die eventuell bereits prozessiert worden sind )

          IF lv_result <> abap_false.
            " VORSICHT : abap_undefined ist auch ein valider Wert !!
            result = abap_true.
          ENDIF.

        CATCH cx_dynamic_check.
      ENDTRY.

    ENDLOOP.
  ENDMETHOD.


  METHOD do_process_fcode_sub.
    rv_processed = super->do_process_fcode_sub( is_get ).

    " FT20261030 Benötigt ??
    IF  rv_processed     = abap_true
    AND ms_control-base IS BOUND.
      DATA(lv_changed) = do_check_changes( ). " Offene Änderungen abarbeiten
      IF lv_changed = abap_true.
*      IF ms_control-base->instance->ms_control-is_changed = abap_true.
        " Wenn Event auf Objekttypen prozessiert werden, die zu einer Knotenänderung geführt haben,
        " Dann Objektlisten aktualisieren ( Marker, Status )
        do_refresh_navigation( ).
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_app~actualize_bindings.
    " Bindings aktualisieren.

    IF ms_control-base IS NOT BOUND.
*      IF is_stateful( ).
*        RETURN.
*      ELSE.
      " Stateless mode (oder Stateful zurück anderer App ) : zuletzt angezeigter Knoten wiederherstellen.
      init_instances( ).
      DATA(lr_base) = get_parameter_base_ref( is_get = VALUE #( t_event_arg = mt_save_arg ) ).
      IF lr_base IS BOUND.
        ms_control-base = lr_base.
        CLEAR mt_sub_app.
        init_objtyp( ).
      ELSE.
        RETURN.
      ENDIF.
*      ENDIF.
    ENDIF.

    " Offene GUI Änderungen an die Objekttypen durchreichen
    IF abap_true = do_check_changes( ).
      do_refresh_navigation( ).
    ENDIF.

    _bind( iv_fieldname = |ms_headerdata-title| ).
    _bind( iv_fieldname = |ms_headerdata-vtext| ).
    _bind( iv_fieldname = |mt_actions| ).
    _bind( iv_fieldname = |ms_status-type| ).
    _bind( iv_fieldname = |ms_status-icon| ).
    _bind( iv_fieldname = |ms_status-text| ).
    _bind( iv_fieldname = |ms_status-act| ).
    _bind( iv_fieldname = |ms_fullscreen-icon| ).
    " Header
    ms_headerdata-vtext = VALUE #( ms_control-base->instance->ms_node_data-nodet[ spras = sy-langu ]-vtext OPTIONAL ).
    IF ms_headerdata-vtext IS INITIAL.
      ms_headerdata-vtext = '-'.
    ENDIF.
    ms_headerdata-title = get_node_objtext( ms_control-base ).

    " Status
    ms_status-text = get_status_text( ).
    ms_status-icon = get_status_icon( ).
    ms_status-type = get_status_type( ).
    ms_control-base->instance->get_allowed_activity( EXPORTING iv_userset    = abap_true
                                                     IMPORTING et_activities = ms_status-act ).

    " Aktionen
    CLEAR mt_actions.
    IF ms_control-base->workmode = mc->workmode_change.

      IF NOT line_exists( ms_control-base->excl_action[ actioncode = mc->action_builder  ] ).
        INSERT VALUE #( text   = mutx->get_text( mutx->u022 )
                        icon   = 'sap-icon://building'
                        action = mcu->events-builder )
               INTO TABLE mt_actions.
      ENDIF.
      IF NOT line_exists( ms_control-base->excl_action[ actioncode = mc->action_globgenmon  ] ).
        INSERT VALUE #( text   = mutx->get_text( mutx->u023 ) " Generierung aktivieren
                        icon   = 'sap-icon://restart'
                        action = mcu->events-builder )
               INTO TABLE mt_actions.
      ENDIF.
      IF NOT line_exists( ms_control-base->excl_action[ actioncode = mc->action_globgenmoff  ] ).
        INSERT VALUE #( text   = mutx->get_text( mutx->u024 ) " Generierung deaktivieren
                        icon   = 'sap-icon://stop'
                        action = mcu->events-glgenmoff )
               INTO TABLE mt_actions.
      ENDIF.
      IF NOT line_exists( ms_control-base->excl_action[ actioncode = mc->action_delete  ] ).
        INSERT VALUE #( text   = mutx->get_text( mutx->u025 )  " Objekt löschen
                        icon   = 'sap-icon://delete'
                        action = mcu->events-delete )
               INTO TABLE mt_actions.
      ENDIF.
      IF NOT line_exists( ms_control-base->excl_action[ actioncode = mc->action_activate ] ).
        INSERT VALUE #( text   = mutx->get_text( mutx->u026 ) " Aktivieren
                        icon   = 'sap-icon://activate'
                        action = mcu->events-activate )
               INTO TABLE mt_actions.
      ENDIF.
    ENDIF.

    LOOP AT mt_sub_app ASSIGNING FIELD-SYMBOL(<app>)
         WHERE app IS BOUND. " Es exisieren noch nicht alle UI Klassen zu allen Objekttypen
      <app>-app->actualize_bindings( ).
    ENDLOOP.

    super->/sct/qp_if_ui_app~actualize_bindings( ).
  ENDMETHOD.


  METHOD get_activity.
    IF strlen( is_get-event ) < 7 OR is_get-event <> 'STATUS_'.
      RETURN.
    ENDIF.

    result = is_get-event+7.

    IF result IS INITIAL.
      result = VALUE #( is_get-t_event_arg[ 3 ] OPTIONAL ).
    ENDIF.
  ENDMETHOD.


  METHOD get_action.
    IF strlen( is_get-event ) >= 7 AND is_get-event = 'ACTION_'.

      result = is_get-event+7.

      IF result IS INITIAL.
        result = VALUE #( is_get-t_event_arg[ 3 ] OPTIONAL ).
      ENDIF.
    ELSE.
      result = is_get-event.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
