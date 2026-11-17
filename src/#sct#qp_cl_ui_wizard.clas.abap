CLASS /sct/qp_cl_ui_wizard DEFINITION
  PUBLIC
  INHERITING FROM /sct/qp_cl_ui_root_app
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES /sct/qp_if_ui_wizard.
    INTERFACES /sct/qp_if_ui_callback.

    ALIASES ms_cb FOR /sct/qp_if_ui_callback~ms_callback.

    TYPES:
      BEGIN OF ty_s_vart,
        vart     TYPE string,
        varttext TYPE string,
      END OF ty_s_vart.

    DATA mv_root   TYPE /sct/qp_vart.
    DATA mv_child  TYPE /sct/qp_vtyp.
    DATA mv_vname  TYPE /sct/qp_vname.
    DATA mv_vbez   TYPE /sct/qp_qvtext.
    DATA mv_object TYPE string.
    DATA mt_tvart  TYPE STANDARD TABLE OF ty_s_vart.
*    DATA mo_toe TYPE REF TO /sct/qp_if_toe .

    CLASS-METHODS class_constructor.
    CLASS-METHODS get_instance RETURNING VALUE(r_result) TYPE REF TO /sct/qp_if_ui_wizard.

    METHODS /sct/au5_if_app~main REDEFINITION.

  PROTECTED SECTION.
    DATA mv_inputstate_root      TYPE string.
    DATA mv_inputstatetext_root  TYPE string.
    DATA mv_inputstate_child     TYPE string.
    DATA mv_inputstatetext_child TYPE string.
    DATA ms_current_location     TYPE /sct/qp_if_ui_objlist=>ty_s_current_location.

    TYPES ty_t_childs TYPE RANGE OF string.

    METHODS do_display_wizard.
    METHODS _do_display_wizard_root  RETURNING VALUE(ro_view) TYPE REF TO /sct/au5_cl_xml_view.
    METHODS _do_display_wizard_child RETURNING VALUE(ro_view) TYPE REF TO /sct/au5_cl_xml_view.

    METHODS do_create_root.
    METHODS do_create_child.

    METHODS _do_check_input_root     RETURNING VALUE(r_error) TYPE abap_boolean.
    METHODS _do_check_input_child    RETURNING VALUE(r_error) TYPE abap_boolean.
    METHODS do_callback              IMPORTING is_get         TYPE /sct/au5_if_client=>ty_s_get.  " AD, 2026.10.09, changed
    METHODS do_wizard_destory.
    METHODS do_rebuild.
    METHODS do_check_input_child     RETURNING VALUE(r_error) TYPE abap_boolean.
    METHODS do_check_input_root      RETURNING VALUE(r_error) TYPE abap_boolean.

    METHODS get_possible_childs IMPORTING iv_guid         TYPE /sct/qp_guid OPTIONAL
                                RETURNING VALUE(r_childs) TYPE /sct/qp_t_thier.

  PRIVATE SECTION.
ENDCLASS.



CLASS /SCT/QP_CL_UI_WIZARD IMPLEMENTATION.


  METHOD /sct/au5_if_app~main.
    TRY.

*        IF mv_stateful = abap_false.
*          mv_stateful = abap_true.
*          client->set_session_stateful( abap_true ).
*        ENDIF.

        ms_control-client ?= client. " AD, 2026.10.09, changed

        DATA(lt_arg) = client->get( )-t_event_arg.
        DATA(lv_event) = client->get( )-event.

        init_instances( ).

        IF check_initialized = abap_false.
          check_initialized = abap_true.
          do_display_wizard( ).
          ms_control-client->popup_model_update( ).
          RETURN.
        ELSEIF ms_control-client->check_on_navigated( ) = abap_true.
          TRY.
              DATA(lo_prev) = ms_control-client->get_app( ms_control-client->get( )-s_draft-id_prev_app ).
              DATA(ls_callback_event) = CAST /sct/qp_if_ui_callback( lo_prev )->get_callback_event( ).
*        ms_control-client->message_box_display( `Navigate back to main App` ).
            CATCH cx_root.
          ENDTRY.
          IF ls_callback_event IS NOT INITIAL.
            lv_event = ls_callback_event-event.
          ENDIF.
          do_display_wizard( ).
          ms_control-client->popup_model_update( ).
        ENDIF.

        CASE lv_event.
          WHEN mcu->events-wiz_shlp.

            IF ms_current_location IS INITIAL.
              " VART search help
              /sct/qp_cl_factory=>get_instance( EXPORTING iv_classname = '/SCT/QP_CL_UI_TOE'
                                                CHANGING  co_instance  = mo_toe ).
              mo_toe->f4_call( is_toe       = VALUE #( element = '/QPPD/VART'
                                                       value   = VALUE #( ) )
                               io_ui_client = client
                               is_callback  = VALUE #( s_get-event       = mcu->events-wiz_f4_back
                                                       s_get-t_event_arg = VALUE #( ( lt_arg[ 1 ] ) ) ) ).
            ELSE.
              " VTYP search help

*            check_initialized = abap_false.
*            ms_control-client->popup_destroy( ).
*            DATA(lo_ui_f4) = /sct/qp_cl_ui_searchhelp=>get_instance( ).
*            lo_ui_f4->init( iv_shlp     = CONV #( lt_arg[ 2 ] )
*                            iv_value    = CONV #( lt_arg[ 1 ] )
*                            is_callback = VALUE #( s_get-event       = mcu->events-wiz_f4_back
*                                                   s_get-t_event_arg =
*            ms_control-client->nav_app_call( CAST /sct/au5_if_app( lo_ui_f4 ) ).

              DATA(lr_base) = mo_ui_handler->get_base( iv_guid     = ms_current_location-guid
                                                       iv_oguid    = ms_current_location-oguid
                                                       iv_stateful = abap_false ).

              /sct/qp_cl_factory=>get_instance( EXPORTING iv_classname = '/SCT/QP_CL_UI_TOE'
                                                CHANGING  co_instance  = mo_toe ).
              " TODO: variable is assigned but never used (ABAP cleaner)
              DATA(lr_val) = mo_toe->add_context( it_context = VALUE #( ( element = '/QPPD/VART'
                                                                          value   = lr_base->ovart )
                                                                        ( element = '/QPPD/HIERA'
                                                                          value   = lr_base->hinfo ) ) ).

              TRY.
                  mo_toe->f4_call( is_toe       = VALUE #( element = '/QPPD/CHILDREN'
                                                           value   = VALUE #( ) )
                                   io_ui_client = client
                                   is_callback  = VALUE #( s_get-event       = mcu->events-wiz_f4_back
                                                           s_get-t_event_arg = VALUE #( ( lt_arg[ 1 ] ) ) ) ).

*                ms_control-client->nav_app_call( CAST /sct/au5_if_app( mo_toe ) ).

                CATCH /sct/qp_cx_error INTO DATA(lo_error2). " TODO: variable is assigned but never used (ABAP cleaner)
                  " Kein TOE ? Standard Suchhilfe aufrufen
                  mo_tools->do_breakpoint( ).
              ENDTRY.
            ENDIF.

          WHEN mcu->events-wiz_f4_back.
            do_callback( ls_callback_event ).
          WHEN mcu->events-wiz_destroy.
            do_wizard_destory( ).
          WHEN mcu->events-wiz_create_root.
            do_create_root( ).
          WHEN mcu->events-wiz_create_child.
            do_create_child( ).
          WHEN mcu->events-wiz_check_input_root.
            do_check_input_root( ).
          WHEN mcu->events-wiz_check_input_child.
            do_check_input_child( ).
          WHEN OTHERS.
        ENDCASE.
      CATCH cx_root INTO DATA(lo_error).
        " Falls etwas schief geht ( z.B. call DYNPRO )
        " TODO: variable is assigned but only used in commented-out code (ABAP cleaner)
        DATA(l_text) = lo_error->get_text( ).
*        popup_error( l_text ).
    ENDTRY.
  ENDMETHOD.


  METHOD class_constructor.
  ENDMETHOD.


  METHOD get_instance.
    /sct/qp_cl_factory=>create_instance( CHANGING co_instance = r_result ).
  ENDMETHOD.


  METHOD /sct/qp_if_ui_wizard~init.
    mv_object = iv_object.
    ms_cb = is_callback.
    ms_current_location = is_current_location.
    ms_control = is_control.
  ENDMETHOD.


  METHOD _do_display_wizard_root.
    " Tabelle für die Vorschläge
    mo_cust->get_tvart( IMPORTING et_tvart = DATA(lt_tvart_hashed) ).
    mt_tvart = VALUE #( FOR <fs_vart> IN lt_tvart_hashed
                        ( vart     = <fs_vart>-vart
                          varttext = <fs_vart>-varttext ) ).

    ro_view = /sct/au5_cl_xml_view=>factory_popup( ).
    DATA(lo_dialog) = ro_view->dialog( title             = mutx->get_text( mutx->u035 ) " Objekt anlegen
                                       showheader        = abap_false
                                       resizable         = 'true'
                                       draggable         = 'true'
                                       contentwidth      = '55%'
                                       contentheight     = '40%'
                                       closeonnavigation = abap_false ).

    DATA(lo_content1) = lo_dialog->content( ).

    DATA(lo_wizard) = lo_content1->wizard( class = 'sapUiResponsivePadding--content'
                                           " complete = lv_complete
                                           ).

    " Step 1 Vart
    DATA(lo_wiz_step1) = lo_wizard->wizard_step( title     = mutx->get_text( mutx->u040 ) " Vorschriftenart
                                                 validated = abap_true " mv_validate_first_step
                                                 activate  = 'vartDefined' ).

    DATA(lo_hbox_s1_1) = lo_wiz_step1->flex_box( alignitems = 'Center' ).
    lo_hbox_s1_1->label( class = 'sapUiTinyMarginEnd'
                         text  = mutx->get_text( mutx->u046 ) ). " Langtext Beschreibung Vart

    DATA(lo_hbox_s1_2) = lo_wiz_step1->flex_box( alignitems = 'Center' ).
    lo_hbox_s1_2->label( class    = 'sapUiTinyMarginEnd'
                         required = 'true'
                         text     = mutx->get_text( mutx->u051 ) ). " Art
    lo_hbox_s1_2->input( class            = 'sapUiTinyMarginEnd'
                         autocomplete     = 'true'
                         placeholder      = | { mutx->get_text( mutx->u058 ) && ` ` && mutx->get_field_length( mv_root ) && ` ` && mutx->get_text( mutx->u057 ) } | " Max. X Zeichen
                         valuestate       = mv_inputstate_root
                         valuestatetext   = mv_inputstatetext_root
                         value            = ms_control-client->_bind( mv_root )
                         showsuggestion   = abap_true
                         suggestionitems  = ms_control-client->_bind( mt_tvart )
                         showvaluehelp    = abap_true
                         valuehelprequest = ms_control-client->_event( val   = mcu->events-wiz_shlp
                                                                       t_arg = VALUE #( ( |{ |VART| }| )
                                                                                        ( |{ |/SCT/QP_SH_VART| }| ) ) )
                         submit           = ms_control-client->_event( mcu->events-wiz_check_input_root ) )->get(
                               )->suggestion_items( )->get(
                                    )->list_item( text           = '{VART}'
                                                  additionaltext = '{VARTTEXT}' ).

    " Step 2 Vname
    DATA(lo_wiz_step2) = lo_wizard->wizard_step( title     = mutx->get_text( mutx->u003 ) " Vorschriftenname
                                                 validated = abap_true
                                                 optional  = abap_true ).
    DATA(lo_hbox_s2_1) = lo_wiz_step2->flex_box( alignitems = 'Center' ).
    lo_hbox_s2_1->label( class = 'sapUiTinyMarginEnd'
                         text  = mutx->get_text( mutx->u047 ) ). " Langtext Beschreibung Vname

    DATA(lo_hbox_s2_2) = lo_wiz_step2->flex_box( alignitems = 'Center' ).
    lo_hbox_s2_2->label( class = 'sapUiTinyMarginEnd'
                         text  = mutx->get_text( mutx->u052 ) ). " Name
    lo_hbox_s2_2->input( class       = 'sapUiTinyMarginEnd'
                         placeholder = | { mutx->get_text( mutx->u058 ) && ` ` && mutx->get_field_length( mv_vname ) && ` ` && mutx->get_text( mutx->u057 ) } | " Max. X Zeichen
                         value       = ms_control-client->_bind_edit( mv_vname ) ).

    " Step 3 Vbez
    DATA(lo_wiz_step3) = lo_wizard->wizard_step( title     = mutx->get_text( mutx->u004 ) " Vorschriftenbezeichnung
                                                 validated = abap_false
                                                 optional  = abap_true ).
    DATA(lo_hbox_s3_1) = lo_wiz_step3->flex_box( alignitems = 'Center' ).
    lo_hbox_s3_1->label( class = 'sapUiTinyMarginEnd'
                         text  = mutx->get_text( mutx->u048 ) ). " Langtext Beschreibung Vbezeichung

    DATA(lo_hbox_s3_2) = lo_wiz_step3->flex_box( alignitems = 'Center' ).
    lo_hbox_s3_2->label( class = 'sapUiTinyMarginEnd'
                         text  = mutx->get_text( mutx->u053 ) ). " Bezeichnung
    lo_hbox_s3_2->input( class       = 'sapUiTinyMarginEnd'
                         placeholder = | { mutx->get_text( mutx->u058 ) && ` ` && mutx->get_field_length( mv_vbez ) && ` ` && mutx->get_text( mutx->u057 ) } | " Max. X Zeichen
                         value       = ms_control-client->_bind_edit( mv_vbez ) ).

    DATA(lo_footer1) = lo_dialog->footer( ).
    DATA(lo_overflowtoolbar1) = lo_footer1->overflow_toolbar( ).
    lo_overflowtoolbar1->toolbar_spacer( ).
    lo_overflowtoolbar1->button( text  = mutx->get_text( mutx->u030 ) " Anlegen
                                 press = ms_control-client->_event( mcu->events-wiz_create_root )
                                 type  = 'Emphasized' ).
    lo_overflowtoolbar1->button( text  = mutx->get_text( mutx->u034 ) " Abbrechen
                                 press = ms_control-client->_event( mcu->events-wiz_destroy )
                                 type  = 'Default' ).
  ENDMETHOD.


  METHOD _do_display_wizard_child.
    " Wizard für das Erstellen eines Unterknotens
*    DATA lt_childs TYPE ty_t_childs.
*    DATA(lt_childs_thier) = get_possible_childs( ).
*
*    " Tabelle für die Vorschläge
*    DATA(lt_childs) = VALUE ty_t_childs( FOR <fs_thier> IN lt_childs_thier
*                                         ( sign   = 'I'
*                                           option = 'EQ'
*                                           low    = COND #( WHEN <fs_thier>-hvart IS NOT INITIAL
*                                                            THEN <fs_thier>-hvart
*                                                            ELSE <fs_thier>-hvtyp )
*                                           high   = <fs_thier>-vart ) ).

    ro_view = /sct/au5_cl_xml_view=>factory_popup( ).

    DATA(lo_dialog) = ro_view->dialog( title        = mutx->get_text( mutx->u075 ) " Position anlegen
                                       showheader   = abap_false
                                       resizable    = 'true'
                                       draggable    = 'true'
                                       contentwidth = '55%' ).

    " Content aggregation
    DATA(lo_content) = lo_dialog->content( ).

    DATA(lo_wizard) = lo_content->wizard( class = 'sapUiResponsivePadding--content'
                                          " complete = lv_complete
                                          ).

    " Step 1 Positionstyp
    DATA(lo_wiz_step_2_1) = lo_wizard->wizard_step( title     = mutx->get_text( mutx->u096 ) " Positionsdaten
                                                    validated = abap_false
                                                    activate  = 'vartDefined' ).

    " DATA("lo_hbox_2_s1_1) = lo_form_s1->flex_box( alignitems = 'Center' ).
    lo_wiz_step_2_1->text( class = 'sapUiTinyMarginEnd'
                           text  = mutx->get_text( mutx->u097 ) ). " Langtext Positionsdaten
    DATA(lo_form_s1) = lo_wiz_step_2_1->simple_form( ).

    DATA(lo_hbox_2_s1_2) = lo_form_s1->flex_box( class      = 'sapUiTinyMarginEnd'
                                                 alignitems = 'Center' ).
    lo_hbox_2_s1_2->label( class    = 'sapUiTinyMarginEnd'
                           required = 'true'
                           text     = mutx->get_text( mutx->u082 ) ). " Typ
    lo_hbox_2_s1_2->input( class                        = 'sapUiTinyMarginEnd'
                           autocomplete                 = 'true'
                           placeholder                  = | { mutx->get_text( mutx->u058 ) && ` ` && mutx->get_field_length( mv_child ) && ` ` && mutx->get_text( mutx->u057 ) } | " Max. X Zeichen
                           valuestate                   = mv_inputstate_child
                           valuestatetext               = mv_inputstatetext_child
                           value                        = ms_control-client->_bind_edit( mv_child )
*                           suggestionitems              = _bind( REF #( lt_childs ) )
*                           showsuggestion               = abap_true
                           showtablesuggestionvaluehelp = abap_true
                           showvaluehelp                = abap_true
                           valuehelprequest             = ms_control-client->_event( val   = mcu->events-wiz_shlp
                                                                                     t_arg = VALUE #( ( |{ |VTYP| }| )
                                                                                                      ( |{ |/SCT/QP_SH_CHILDS| }| ) ) )
                           submit                       = ms_control-client->_event( mcu->events-wiz_check_input_root ) )->get(
                               )->suggestion_items( )->get(
                                    )->list_item( text           = '{LOW}'
                                                  additionaltext = '{HIGH}' ).
*        submit          = ms_control-client->_event( mcu->events-wiz_create_child ) )->get(
*                             )->suggestion_items( )->get(
*                                  )->list_item( text           = '{LOW}'
*                                                additionaltext = '{HIGH}' ).

    " Step 2 Vname
*          DATA(lo_wiz_step_2_2) = lo_wizard_2->wizard_step( title     = mutx->get_text( mutx->u079 ) " Positionsname
*                                                            validated = abap_false
*                                                            activate  = 'vartDefined' ).

    " DATA(lo_hbox_2_s2_1) = lo_wiz_step_2_1->flex_box( alignitems = 'Center' ).
*          lo_wiz_step_2_1->label( class = 'sapUiTinyMarginEnd'
*                                  text  = mutx->get_text( mutx->u081 ) ). " Langtext Beschreibung Positionsnamename
    DATA(lo_hbox_2_s2_2) = lo_form_s1->flex_box( class      = 'sapUiTinyMarginEnd'
                                                 alignitems = 'Center' ).
    lo_hbox_2_s2_2->label( class    = 'sapUiTinyMarginEnd'
                           required = 'true'
                           text     = mutx->get_text( mutx->u052 ) ). " Name
    lo_hbox_2_s2_2->input( class        = 'sapUiTinyMarginEnd'
                           autocomplete = 'true'
                           placeholder  = | { mutx->get_text( mutx->u058 ) && ` ` && mutx->get_field_length( mv_vname ) && ` ` && mutx->get_text( mutx->u057 ) } | " Max. X Zeichen
                           value        = ms_control-client->_bind_edit( mv_vname )
                           submit       = ms_control-client->_event( mcu->events-wiz_create_child ) ).

    DATA(lo_footer_2_1) = lo_dialog->footer( ).
    DATA(lo_overflowtoolbar_2_1) = lo_footer_2_1->overflow_toolbar( ).
    lo_overflowtoolbar_2_1->toolbar_spacer( ).
    lo_overflowtoolbar_2_1->button( text  = mutx->get_text( mutx->u030 ) " Anlegen
                                    press = ms_control-client->_event( mcu->events-wiz_create_child )
                                    type  = 'Emphasized' ).
    lo_overflowtoolbar_2_1->button( text  = mutx->get_text( mutx->u034 ) " Abbrechen
                                    press = ms_control-client->_event( mcu->events-wiz_destroy )
                                    type  = 'Default' ).
  ENDMETHOD.


  METHOD do_create_child.
    IF do_check_input_child( ) = abap_true.
      RETURN.
    ENDIF.

    CLEAR ms_cb-s_get-t_comp_params.
    ms_cb-cancelled = abap_false.

    INSERT INITIAL LINE INTO TABLE ms_cb-result_tab ASSIGNING FIELD-SYMBOL(<lt_result>).
    INSERT VALUE #( n = 'VTYP'
                    v = mv_child ) INTO TABLE <lt_result>.
    INSERT VALUE #( n = 'VBEZ'
                    v = mv_vbez ) INTO TABLE <lt_result>.
    INSERT VALUE #( n = 'VNAME'
                    v = mv_vname ) INTO TABLE <lt_result>.
    INSERT VALUE #( n = 'PARENT'
                    v = ms_current_location-guid ) INTO TABLE <lt_result>.

    ms_control-client->popup_destroy( ).
*    ms_control-client->nav_app_leave( ms_control-client->get_app( ms_control-client->get( )-s_draft-id_prev_app_stack ) ).
    ms_control-client->nav_app_leave( ).
  ENDMETHOD.


  METHOD do_create_root.
    IF do_check_input_root( ) = abap_true.
      RETURN.
    ENDIF.

    CLEAR ms_cb-s_get-t_comp_params.
    ms_cb-cancelled = abap_false.

    INSERT INITIAL LINE INTO TABLE ms_cb-result_tab ASSIGNING FIELD-SYMBOL(<lt_result>).
    INSERT VALUE #( n = 'VART'
                    v = mv_root ) INTO TABLE <lt_result>.
    INSERT VALUE #( n = 'VBEZ'
                    v = mv_vbez ) INTO TABLE <lt_result>.
    INSERT VALUE #( n = 'VNAME'
                    v = mv_vname ) INTO TABLE <lt_result>.

    ms_control-client->popup_destroy( ).
    ms_control-client->nav_app_leave( ms_control-client->get_app( ms_control-client->get( )-s_draft-id_prev_app_stack ) ).
  ENDMETHOD.


  METHOD _do_check_input_root.
    r_error = abap_false.

    TRANSLATE mv_root TO UPPER CASE.

    IF mv_root IS INITIAL.
      r_error = abap_true.
      RETURN.
    ENDIF.

    mo_cust->get_tvart( EXPORTING iv_vart  = mv_root
                        IMPORTING es_tvart = DATA(ls_tvart) ).

    IF ls_tvart IS INITIAL.
      r_error = abap_true.
      RETURN.
    ENDIF.
  ENDMETHOD.


  METHOD do_callback.
    LOOP AT is_get-t_comp_params ASSIGNING FIELD-SYMBOL(<param>).
      CASE <param>-n.
        WHEN 'VART'.
          mv_root = <param>-v.
        WHEN 'HVTYP'.
          mv_child = <param>-v.
      ENDCASE.
      EXIT.
    ENDLOOP.
  ENDMETHOD.


  METHOD do_display_wizard.
    CASE mv_object.
      WHEN 'root'.
        DATA(lo_view) = _do_display_wizard_root( ).
      WHEN 'child'.
        lo_view = _do_display_wizard_child( ).
    ENDCASE.

    ms_control-client->popup_display( lo_view->stringify( ) ).
  ENDMETHOD.


  METHOD /sct/qp_if_ui_callback~get_callback_event.
    IF ms_cb-cancelled = abap_false.
      " Komplette Ergebnistabelle ( alle Return-Parameter aller selektieren Zeilen )
      ms_cb-s_get-r_event_data  = REF #( ms_cb-result_tab ).
      " Erste selektierte Zeile
      ms_cb-s_get-t_comp_params = VALUE #( ms_cb-result_tab[ 1 ] OPTIONAL ).
      result = ms_cb-s_get.
    ENDIF.
  ENDMETHOD.


  METHOD do_wizard_destory.
    ms_cb-cancelled = abap_true.
    ms_control-client->popup_destroy( ).
    ms_control-client->nav_app_leave( ms_control-client->get_app( ms_control-client->get( )-s_draft-id_prev_app_stack ) ).
  ENDMETHOD.


  METHOD _do_check_input_child.
    r_error = abap_false.

    TRANSLATE mv_child TO UPPER CASE.

    IF mv_child IS INITIAL.
      r_error = abap_true.
      RETURN.
    ENDIF.

    DATA(lt_childs) = get_possible_childs( ).

    " Ist das eingegebene Kind ein direktes Kind
    DATA(lv_found) = abap_false.
    " TODO: variable is assigned but never used (ABAP cleaner)
    LOOP AT lt_childs ASSIGNING FIELD-SYMBOL(<ls_childs>) WHERE hvtyp = mv_child
                                                             OR hvart = mv_child.
      lv_found = abap_true.
      EXIT.
    ENDLOOP.

    IF lv_found = abap_false.
      r_error = abap_true.
    ENDIF.
  ENDMETHOD.


  METHOD do_rebuild.
    ms_control-client->popup_destroy( ).
    do_display_wizard( ).
    ms_control-client->popup_model_update( ).
  ENDMETHOD.


  METHOD do_check_input_child.
    IF _do_check_input_child( ) = abap_true.
      r_error = abap_true.
      mv_inputstate_child = 'Error'.
      IF mv_root IS INITIAL.
        mv_inputstatetext_child = mutx->get_text( mutx->u077 ). " Fehlender Wert
      ELSE.
        mv_inputstatetext_child = mutx->get_text( mutx->u076 ). " Falscher Wert
      ENDIF.
      do_rebuild( ).
    ENDIF.
  ENDMETHOD.


  METHOD do_check_input_root.
    IF _do_check_input_root( ) = abap_true.
      r_error = abap_true.
      mv_inputstate_root = 'Error'.
      IF mv_root IS INITIAL.
        mv_inputstatetext_root = mutx->get_text( mutx->u076 ). " Falscher Wert
      ELSE.
        mv_inputstatetext_root = mutx->get_text( mutx->u077 ). " Fehlender Wert
      ENDIF.
      do_rebuild( ).
    ENDIF.
  ENDMETHOD.


  METHOD get_possible_childs.
    DATA(lv_guid) = iv_guid.

    IF lv_guid IS INITIAL.
      lv_guid = ms_current_location-guid.
    ENDIF.

    " FT20251222 BUS lädt immer die Daten im Standard CL_QV_MODEL.
    " im Stateless Modus ist der Schritt nicht notwendig

    DATA(lr_base) = mo_ui_handler->get_base( iv_guid     = lv_guid                 " Vorschriften GUID
                                             iv_oguid    = ms_current_location-oguid                 " Original GUID; Zuordnung zur Kopfvorschrift
*                                             iv_stateful = check_sticky( )
                                             iv_stateful = abap_false ). " Nachladen mit Objekttypdaten
    IF lr_base IS BOUND.
      DATA(ls_base) = lr_base->*.
    ENDIF.
**    mo_bus->read( EXPORTING iv_guid   = lv_guid
**                  IMPORTING et_base   = DATA(lt_base)
**                           " TODO: variable is assigned but never used (ABAP cleaner)
**                            et_return = DATA(lt_return)
**                           " TODO: variable is assigned but never used (ABAP cleaner)
**                            ev_error  = DATA(lv_error) ).
**
**    DATA(ls_base) = VALUE #( lt_base[ guid = lv_guid ] OPTIONAL ).

    IF ls_base IS INITIAL.
      RETURN.
    ENDIF.

    " Kinder bekommen
    DATA(lt_thier) = mo_cust->get_thier_childs( iv_vart  = ls_base-ovart
                                                iv_hiera = ls_base-instance->ms_node_data-hiera ).

*    SORT lt_thier BY level ASCENDING.

    " Das Level der direkten Kinder bestimmen
    DATA(lv_level) = VALUE #( lt_thier[ 1 ]-level OPTIONAL ).
    IF lv_level IS INITIAL.
      RETURN.
    ENDIF.

    " Nur originale Kinder berücksichtigen
    LOOP AT lt_thier ASSIGNING FIELD-SYMBOL(<ls_thier>) WHERE level    = lv_level
                                                          AND relattyp = mc->relattyp_original.
      INSERT <ls_thier> INTO TABLE r_childs.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
