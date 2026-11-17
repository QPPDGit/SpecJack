CLASS /sct/qp_cl_ui_searchhelp DEFINITION
  PUBLIC
  INHERITING FROM /sct/qp_cl_ui_root_app
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES /sct/qp_if_ui_callback.
    INTERFACES /sct/qp_if_ui_searchhelp.

    ALIASES ms_cb FOR /sct/qp_if_ui_callback~ms_callback.

    DATA mr_data      TYPE REF TO data.
    DATA mr_data_temp TYPE REF TO data.
    DATA ms_shlp      TYPE shlp_descr.
    DATA mt_selfields TYPE STANDARD TABLE OF /sct/qp_if_ui_searchhelp=>tys_input WITH EMPTY KEY.
    " data MT_MAPPING type /SCT/AU5_IF_TYPES=>TY_T_NAME_VALUE .
    DATA ms_toe       TYPE /sct/qp_s_toe.
    DATA mv_maxrows   TYPE ddshmaxrec.
    DATA ms_coll_shlp TYPE /sct/qp_if_ui_searchhelp=>ty_coll_shlp.

    CONSTANTS:
      BEGIN OF const,
        BEGIN OF messagetype,
          error       TYPE string VALUE 'Error',
          information TYPE string VALUE 'Information',
          none        TYPE string VALUE 'None',
          success     TYPE string VALUE 'Success',
          warning     TYPE string VALUE 'Warning',
        END OF messagetype,
      END OF const.

    CLASS-DATA:
      BEGIN OF ms_const,
        text_tbmaxsel TYPE scrtext_l,
        text_shlpname TYPE scrtext_l,
      END OF ms_const.

    DATA mv_strip_show          TYPE abap_bool.
    DATA mv_strip_message       TYPE string.
    DATA mv_strip_type          TYPE string VALUE const-MessageType-information ##NO_TEXT.
    DATA mv_expand_searchfields TYPE abap_bool.
    DATA mv_immediate_selection TYPE abap_bool.
    DATA mv_ok_active           TYPE abap_bool.
    DATA mv_multi_allowed       TYPE abap_bool.

    CLASS-METHODS class_constructor.
    CLASS-METHODS get_instance RETURNING VALUE(r_result) TYPE REF TO /sct/qp_if_ui_searchhelp.

    METHODS /sct/au5_if_app~main REDEFINITION.

  PROTECTED SECTION.
    METHODS do_set_selopt IMPORTING iv_value  TYPE string
                          CHANGING  cs_selopt TYPE ddshselopt.

    METHODS do_selfields_to_selopt.

    METHODS init_shlp IMPORTING iv_shlp        TYPE shlpname
                      RETURNING VALUE(rs_shlp) TYPE shlp_descr.

    METHODS popup_error IMPORTING iv_msg TYPE string.
    METHODS do_button_cancel.
    METHODS do_button_confirm.

    METHODS do_build_out_table IMPORTING it_descr           TYPE dfies_tab
                                         iv_check_fieldprop TYPE abap_bool OPTIONAL
                               EXPORTING et_checkbox        TYPE string_table.

    METHODS do_fill_out_table IMPORTING it_descr TYPE dfies_tab
                                        it_out   TYPE ddshreslts.

    METHODS do_prepare_intf_selopt    CHANGING  cs_shlp  TYPE shlp_descr.
    METHODS do_display_table          IMPORTING io_xml   TYPE REF TO /sct/au5_cl_xml_view.
    METHODS do_display_uitable        IMPORTING io_xml   TYPE REF TO /sct/au5_cl_xml_view.
    METHODS do_select_data.
    METHODS do_build_selection_fields IMPORTING io_items TYPE REF TO /sct/au5_cl_xml_view.
    METHODS do_display.

    METHODS conv_ex2in IMPORTING is_dfies TYPE dfies
                       CHANGING  cv_value TYPE csequence.

    METHODS conv_in2ex IMPORTING is_dfies TYPE dfies
                       CHANGING  cv_value TYPE csequence.

  PRIVATE SECTION.
ENDCLASS.



CLASS /SCT/QP_CL_UI_SEARCHHELP IMPLEMENTATION.


  METHOD get_instance.
    /sct/qp_cl_factory=>create_instance( CHANGING co_instance = r_result ).
  ENDMETHOD.


  METHOD /sct/qp_if_ui_searchhelp~init.
    " Globale Datenstruktur setzen.
    " Suchilfe beschreibung auslesen fuer * setzen

    CLEAR : ms_shlp,
            ms_coll_shlp,
            mv_strip_show.

    " Entweder eine vollständige is_toe-Struktur oder iv_shlp.
    IF is_toe IS INITIAL AND iv_shlp IS INITIAL.
      RETURN.
    ENDIF.

    mv_multi_allowed = iv_multi_result.

    /sct/qp_cl_factory=>get_instance( EXPORTING iv_classname = '/SCT/QP_CL_UI_TOE'
                                      CHANGING  co_instance  = mo_toe ).

    IF mo_toe IS BOUND.
      IF iv_value IS NOT INITIAL.
        ms_toe = mo_toe->get_toe_structure( VALUE #( BASE is_toe
                                                     value = iv_value ) ).
      ELSE.
        ms_toe = mo_toe->get_toe_structure( is_toe ).
      ENDIF.
    ENDIF.

    IF is_callback IS NOT INITIAL.
      ms_cb = is_callback.
    ENDIF.

    /sct/qp_cl_sx_toe=>set_toe( io_toe = mo_toe
                                is_toe = ms_toe ).

    IF iv_shlp IS INITIAL AND ms_toe-gruelm IS BOUND AND ms_toe-gruelm->tobel IS BOUND.
      DATA(lv_shlp) = ms_toe-gruelm->tobel->shlp.
    ELSE.
      lv_shlp = iv_shlp.
    ENDIF.

    ms_shlp-shlpname = lv_shlp.
  ENDMETHOD.


  METHOD do_display.
    DATA(lo_popup) = /sct/au5_cl_xml_view=>factory_popup( ).

    DATA(lv_title) = ms_coll_shlp-shlp_descr-intdescr-ddtext.
    DATA(lt_columns) = ms_shlp-fieldprop.
    DELETE lt_columns WHERE shlplispos = 0.
    DATA(lv_cols) = lines( lt_columns ).

    " Fensterbreite min 30% max 80% der Bildschirmbreite
    DATA(lv_dialog_width) = |{ lv_cols * 15 }|.
    IF lv_dialog_width < 30.
      lv_dialog_width = 30.
    ELSEIF lv_dialog_width > 80.
      lv_dialog_width = 80.
    ENDIF.
    lv_dialog_width = |{ lv_dialog_width }%|.
    lv_dialog_width = condense( val = lv_dialog_width
                                to  = `` ).

    DATA(lo_dialog) = lo_popup->dialog( afterclose   = ms_control-client->_event( 'BUTTON_CANCEL' )
                                        draggable    = abap_true
                                        resizable    = abap_true
                                        contentwidth = lv_dialog_width ).
    " *********************************************************************
    mv_expand_searchfields = abap_true.
    DATA(lo_dyn) = lo_dialog->dynamic_page( headerexpanded = ms_control-client->_bind_edit( mv_expand_searchfields ) ).
    DATA(lo_header_title) = lo_dyn->title( ns = 'f' )->get( )->dynamic_page_title( ).

    " TODO: variable is assigned but never used (ABAP cleaner)
    DATA(lo_box) = lo_dyn->header( )->dynamic_page_header( pinnable = abap_true )->flex_box( ).

    DATA(lo_exp) = lo_header_title->expanded_content( 'f' )->simple_form( editable    = abap_true
                                                                          labelspans  = '12'
                                                                          labelspanm  = '12'
                                                                          labelspanl  = '12'
                                                                          labelspanxl = '12'
                                                          )->label( design    = 'Bold'
                                                                    text      = lv_title
                                                                    class     = 'sapUiTinyMarginBeginEnd'
                                                                    showcolon = abap_true ).

    DATA(lo_snap) = lo_header_title->snapped_content( 'f' )->simple_form( editable    = abap_true
                                                                          labelspans  = '12'
                                                                          labelspanm  = '12'
                                                                          labelspanl  = '12'
                                                                          labelspanxl = '12'
                                                          )->label( design    = 'Bold'
                                                                    text      = lv_title
                                                                    class     = 'sapUiTinyMarginBeginEnd'
                                                                    showcolon = abap_true ).

    " Combo für Einzelsuchhilfen aus einer Sammelsuchhilfe
    IF line_exists( ms_coll_shlp-t_shlp[ 2 ] ).
      ms_coll_shlp-def_shlp = ms_shlp-shlpname.
      ms_coll_shlp-def_text = ms_coll_shlp-t_shlp[ shlpname = ms_coll_shlp-def_shlp ]-intdescr-ddtext.

      DATA(lo_cbo_exp) = lo_exp->combobox( width       = `20rem`
                                           change      = ms_control-client->_event( 'CBO_CHANGE' )
                                           selectedkey = ms_control-client->_bind_edit( val = ms_coll_shlp-def_shlp )
                                           value       = ms_control-client->_bind_edit( val = ms_coll_shlp-def_text )
                                           items       = ms_control-client->_bind_edit( val = ms_coll_shlp-t_shlp  )

                     )->item( key  = '{SHLPNAME}'
                              text = '{INTDESCR/DDTEXT}'
                     )->get_parent( )->get_parent( ).

      " TODO: variable is assigned but never used (ABAP cleaner)
      DATA(lo_cbo_snap) = lo_snap->combobox( width       = `20rem`
                                             change      = ms_control-client->_event( 'CBO_CHANGE' )
                                             selectedkey = ms_control-client->_bind_edit( val = ms_coll_shlp-def_shlp )
                                             value       = ms_control-client->_bind_edit( val = ms_coll_shlp-def_text )
                                             items       = ms_control-client->_bind_edit( val = ms_coll_shlp-t_shlp  )

               )->item( key  = '{SHLPNAME}'
                        text = '{INTDESCR/DDTEXT}'
               )->get_parent( )->get_parent( ).

    ELSE.

      lo_cbo_exp = lo_exp.
      lo_snap->invisible_text( ns   = 'core'
                               text = ' ' ).
    ENDIF.

    " ---------- Set Filter bar -----------------------------------------------------------------------
    DATA(lr_filter_bar) = lo_cbo_exp->filter_bar( search = ms_control-client->_event( val = 'SEARCH' ) ).
    DATA(lo_items) = lr_filter_bar->filter_group_items( ).

    " Selectionsfelder aufbauen
    do_build_selection_fields( io_items = lo_items ).

    lo_dialog->message_strip( text     = ms_control-client->_bind_edit( val = mv_strip_message )
                              type     = ms_control-client->_bind_edit( val = mv_strip_type )
                              visible  = ms_control-client->_bind_edit( val = mv_strip_show )
                              showicon = abap_true ).

    IF mv_strip_type <> const-MessageType-error.
      " Bei früheren Fehler die Selektion nicht ausführen.
      " Die Suchhilfe ist vermutlich kaputt.
      IF mv_immediate_selection = abap_true.
*      IF ms_shlp-intdescr-dialogtype = 'D' " Sofortige Werteanzeige
*      OR ms_shlp-intdescr-dialogtype = 'A'.
        do_select_data( ).
        mv_expand_searchfields = abap_false.
      ENDIF.
    ENDIF.

    do_display_uitable( lo_dialog ).

    lo_dialog->buttons(

       )->button( text  = mutx->get_text( mutx->u034 ) " Abbrechen
                  press = ms_control-client->_event( 'BUTTON_CANCEL' )
       )->button( text    = mutx->get_text( mutx->u033 ) " Ok
                  press   = ms_control-client->_event( 'BUTTON_CONFIRM' )
                  type    = 'Emphasized'
                  enabled = ms_control-client->_bind_edit( val = mv_ok_active ) ).

    ms_control-client->popup_display( lo_popup->stringify( ) ).
  ENDMETHOD.


  METHOD /sct/au5_if_app~main.
    TRY.
        ms_control-client = client.
*        CLEAR : "ms_toe-toec,
*                ms_toe-gruelm.
        init_instances( ).
        IF ms_shlp-shlpname IS NOT INITIAL.
          " Suchhilfedefinition einlesen
          IF check_initialized = abap_false.
            ms_shlp = init_shlp( ms_shlp-shlpname ).
            check_initialized = abap_true.
            do_display( ).
            ms_control-client->popup_model_update( ).
            " ms_toe-TOEC enthält Referenzen die nicht überleben wenn eine neue App gestartet wird.
            " und muss deshalb hier gecleared werden, sonst dumpts bei MAIN_END() bzw. /SCT/AU5_CL_CORE_APP=>ALL_XML_STRINGIFY
            " bzw /SCT/AU5_CL_CORE_SRV_ATTRI=>ATTRI_BEFORE_SAVE

            CLEAR : ms_toe-toec,
                    ms_toe-gruelm,
* FT20261112 Jetzt dass Objekttypinstanzen auch bei AU5-RTTI aufgelöst werden müssen die hier auch gecleard werden                  .
* siehe /SCT/AU5_CL_UI5_SRV_MODEL=>MAIN_ATTRI_REATTACH
                  ms_toe-o_mamba,
                  ms_toe-o_node.
            RETURN.
          ENDIF.
        ENDIF.

        DATA(lt_arg) = client->get( )-t_event_arg.
        DATA(lv_event) = client->get( )-event.
        CASE lv_event.

          WHEN `BUTTON_CONFIRM`.
            do_button_confirm( ).
          WHEN `BUTTON_CANCEL`.
            do_button_cancel( ).
          WHEN 'EVT_SHLP_SELOPT_TOKEN_UPD'.
            DATA(lr_selfield) = REF #( mt_selfields[ fieldname = lt_arg[ 1 ] ] OPTIONAL ).
            IF lr_selfield IS NOT BOUND.
              RETURN.
            ENDIF.
            IF lt_arg[ 2 ] = `removed`.
              DELETE lr_selfield->token WHERE key = lt_arg[ 3 ].
            ENDIF.
            do_select_data( ).

          WHEN 'EVT_SHLP_SELOPT_CHANGE'.
            lr_selfield = REF #( mt_selfields[ fieldname = lt_arg[ 1 ] ] OPTIONAL ).
            IF lr_selfield IS NOT BOUND.
              RETURN.
            ENDIF.
            INSERT VALUE #( key      = lr_selfield->value
                            text     = lr_selfield->value
                            visible  = abap_true
                            editable = abap_true ) INTO TABLE lr_selfield->token.
            CLEAR lr_selfield->value.
            client->popup_model_update( ).
            do_select_data( ).

          WHEN 'SEARCH'.
            do_select_data( ).

          WHEN 'CBO_CHANGE'.
            " Auswahl Einzelsuchhilfe zu Sammelsuchhilfe
            ms_shlp = ms_coll_shlp-t_shlp[ shlpname = ms_coll_shlp-def_shlp ].
            mv_strip_show = abap_false.
            CLEAR mr_data->*.
            do_display( ).

          WHEN 'SELECT'.
*        BREAK-POINT.

          WHEN OTHERS.

        ENDCASE.

        CLEAR : ms_toe-toec,
                ms_toe-gruelm.

      CATCH cx_root INTO DATA(lo_error).
        " Falls etwas schief geht ( z.B. call DYNPRO )
        DATA(l_text) = lo_error->get_text( ).
        popup_error( l_text ).
    ENDTRY.
  ENDMETHOD.


  METHOD do_build_selection_fields.
    DATA(lt_selfields) = ms_shlp-fieldprop.
    SORT lt_selfields BY shlpselpos.

    LOOP AT lt_selfields ASSIGNING FIELD-SYMBOL(<prop>).

      DATA(lr_field) = REF #( ms_shlp-fielddescr[ fieldname = <prop>-fieldname ] OPTIONAL ).
      IF lr_field IS NOT BOUND.
        CONTINUE.
      ENDIF.

      DATA(lr_itfc) = REF #( ms_shlp-interface[ shlpfield = lr_field->fieldname ] OPTIONAL ).
      IF lr_itfc IS NOT BOUND.
        INSERT VALUE #( shlpfield = lr_field->fieldname ) INTO TABLE ms_shlp-interface REFERENCE INTO lr_itfc.
      ENDIF.
      IF <prop>-shlpselpos <= '00'.
        CONTINUE.
      ENDIF.
      "
      " Vorbelegung der Suchfelder (1st time)
      DATA(lr_sel) = REF #( ms_shlp-selopt[ shlpfield = <prop>-fieldname ] OPTIONAL ).
      IF lr_sel IS BOUND AND lr_sel->low IS NOT INITIAL.
        lr_itfc->value = lr_sel->low.
      ENDIF.

      " ---------- Set filter ---------------------------------------------------------------------------
      DATA(lo_filter) = io_items->filter_group_item( name               = lr_field->fieldname
                                                     label              = lr_field->scrtext_l
                                                     groupname          = |Selection|
                                                     visibleinfilterbar = 'true'
                                                                          )->filter_control( ).

      " ---------- Set combo box input field ------------------------------------------------------------

      " Vorsicht im Fall von Sammelsuchhilfen werden die Felder mehreren Suchhilfen hier gesammelt
      ASSIGN mt_selfields[ fieldname = lr_field->fieldname ] TO FIELD-SYMBOL(<selfield>).
      IF sy-subrc = 0.
        DATA(lv_idx) = sy-tabix.
        <selfield>-value = lr_itfc->value.
      ELSE.
        APPEND VALUE #( fieldname = lr_field->fieldname
                        value     = lr_itfc->value )
               TO mt_selfields ASSIGNING <selfield>.
        lv_idx = sy-tabix.
      ENDIF.
      IF <selfield>-value IS NOT INITIAL.
        DATA(lv_text) = CONV text1000( <selfield>-value ).
        conv_in2ex( EXPORTING is_dfies = ms_shlp-fielddescr[ fieldname = <selfield>-fieldname ]
                    CHANGING  cv_value = lv_text ).
        <selfield>-value = lv_text.
      ENDIF.

      lo_filter->multi_input( " id          = lv_id
                              placeholder = lr_field->fieldtext
                              tokens      = ms_control-client->_bind_edit( val       = <selfield>-token
                                                                           tab       = mt_selfields
                                                                           tab_index = lv_idx )
                              value       = ms_control-client->_bind_edit( val       = <selfield>-value
                                                                           tab       = mt_selfields
                                                                           tab_index = lv_idx )
                              tokenupdate = ms_control-client->_event( val   = 'EVT_SHLP_SELOPT_TOKEN_UPD'
                                                                       t_arg = VALUE #( (  CONV #( lr_field->fieldname ) )
                                                                                        ( `$event.mParameters.type` )
                                                                                        ( `$event.mParameters.removedTokens[0].mProperties.key` ) ) )
                              change      = ms_control-client->_event( val   = 'EVT_SHLP_SELOPT_CHANGE'
                                                                       t_arg = VALUE #( ( CONV #( lr_field->fieldname ) ) ) )

                              submit      = _event( 'SEARCH' ) )->item( key  = `{KEY}`
                                                                        text = `{TEXT}`
                              )->tokens( )->token( key      = `{KEY}`
                                                   text     = `{TEXT}`
                                                   visible  = `{VISIBLE}`
                                                   selected = `{SELKZ}`
                                                   editable = `{EDITABLE}` ).

    ENDLOOP.

* Max Anzahl anfügen
*      " ---------- Set filter ---------------------------------------------------------------------------
    lo_filter = io_items->filter_group_item( name               = 'MAXROWS'
                                             label              = ms_const-text_tbmaxsel
                                             groupname          = |Selection|
                                             visibleinfilterbar = 'true'
                                                                  )->filter_control( ).
    lo_filter->input( " id     = 'QP_F4_MAXROWS'
                      value  = ms_control-client->_bind_edit( val = mv_maxrows )
                      submit = _event( 'SEARCH' ) ).
  ENDMETHOD.


  METHOD do_display_table.
    DATA(lo_table) = io_xml->table( alternaterowcolors = abap_true
*                                    id                 = |QP_F4_TAB|
                                    items              = ms_control-client->_bind_edit( mr_data->* )
                                    mode               = 'SingleSelectMaster'
                                    showseparators     = `True`
                                    selectionchange    = ms_control-client->_event( 'SELECT' ) ).

    DATA(lo_cells) = lo_table->items( )->column_list_item( selected = '{F4_SEL}'
                                                         )->cells( ).
    DATA(lt_columns) = ms_shlp-fieldprop.
    SORT lt_columns BY shlplispos.
    DELETE lt_columns WHERE shlplispos = 0.
    DATA(lv_count) = lines( lt_columns ).

    LOOP AT lt_columns ASSIGNING FIELD-SYMBOL(<col>).

      DATA(ls_description) = VALUE #( ms_shlp-fielddescr[ fieldname = <col>-fieldname ] OPTIONAL ).

      IF lv_count < 4.
        DATA(lv_col_title) = ls_description-scrtext_l.
*      ELSEIF lv_count < 10.
*        lv_col_title = ls_description-scrtext_m.
      ELSE.
*        lv_col_title = ls_description-scrtext_s.
        lv_col_title = ls_description-scrtext_m.
      ENDIF.

      lo_table->columns( )->column( )->text( text     = lv_col_title
                                             wrapping = abap_false ).

      " Checkbox ?
      IF ls_description-mask+6(1) = 'X'.
        lo_cells->checkbox( selected = |\{{ <col>-fieldname }_CHECKBOX\}|
                            enabled  = abap_false ).
      ELSE.
        lo_cells->text( text = |\{{ <col>-fieldname }\}| ).
      ENDIF.

    ENDLOOP.
  ENDMETHOD.


  METHOD do_select_data.
    DATA lt_values    TYPE TABLE OF seahlpres. " Ergebnisse (DB-Format)
    DATA lt_out       TYPE TABLE OF seahlpres. " Ergebnisse (Anzeigeformat)
    DATA lt_descr_out TYPE TABLE OF dfies.     " Tabellenbeschreibung
    DATA ls_ocx       TYPE ddshocxint.
    DATA ls_callctrl  TYPE ddshf4ctrl.

    " Eingegebene Selektionsfelder als SELOPT umwandeln
    do_selfields_to_selopt( ).

    " TOE setzen
    DATA(ms_toe) = mo_toe->get_toe_structure( ms_toe ).

    /sct/qp_cl_sx_toe=>set_toe( io_toe = mo_toe
                                is_toe = ms_toe ).

    ls_callctrl-maxrecords = mv_maxrows.
    ls_callctrl-hide_list  = abap_true.

    ls_callctrl-step       = 'SELECT'.
    CALL FUNCTION 'DD_SHLP_SINGLE_STEP' TABLES   shlp_tab     = ms_coll_shlp-t_shlp
                                                 record_tab   = lt_values
                                        CHANGING shlp_top     = ms_coll_shlp-shlp_descr
                                                 shlp_curr    = ms_shlp
                                                 callcontrol  = ls_callctrl
                                                 ocxinterface = ls_ocx.

    ls_callctrl-step = 'DISP'.
    CALL FUNCTION 'DD_SHLP_SINGLE_STEP' TABLES   shlp_tab     = ms_coll_shlp-t_shlp
                                                 record_tab   = lt_values
                                        CHANGING shlp_top     = ms_coll_shlp-shlp_descr
                                                 shlp_curr    = ms_shlp
                                                 callcontrol  = ls_callctrl
                                                 ocxinterface = ls_ocx.

    SORT ms_shlp-fielddescr BY position.

    CALL FUNCTION 'F4IF_CONVERSION_IN2EX' TABLES records_in   = lt_values
                                                 recdescr_in  = ms_shlp-fielddescr
                                                 records_out  = lt_out
                                                 recdescr_out = lt_descr_out.

    mv_strip_show = abap_true.
    IF ls_callctrl-maxexceed IS NOT INITIAL.
      mv_strip_type = const-MessageType-information.
      MESSAGE s803(dh) WITH mv_maxrows INTO mv_strip_message.
    ELSE.
      MESSAGE s215(/sct/qp) WITH CONV char10( lines( lt_values ) ) INTO mv_strip_message.
      mv_strip_type = const-MessageType-success.
    ENDIF.

    do_fill_out_table( it_descr = lt_descr_out
                       it_out   = lt_out ).
    IF ms_control-client IS BOUND.
      ms_control-client->popup_model_update( ).
    ENDIF.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_callback~get_callback_event.
    IF ms_cb-cancelled = abap_false.
      " Komplette Ergebnistabelle ( alle Return-Parameter aller selektieren Zeilen )
      ms_cb-s_get-r_event_data  = REF #( ms_cb-result_tab ).
      " Erste selektierte Zeile
      ms_cb-s_get-t_comp_params = VALUE #( ms_cb-result_tab[ 1 ] OPTIONAL ).
      IF ms_cb-fieldname IS NOT INITIAL.
        INSERT ms_cb-fieldname INTO TABLE ms_cb-s_get-t_event_arg. " Suchhilfe-Feld mitteilen falls angegeben.
      ENDIF.
      result = ms_cb-s_get.
    ENDIF.
  ENDMETHOD.


  METHOD do_display_uitable.
    " Ohne Tabelle keine Daten
    IF mr_data IS NOT BOUND.
      io_xml->text( 'No Columns defined' ).
      RETURN.
    ENDIF.

    DATA(lv_theme) = get_theme( ).
    DATA(lv_keycolor) = `Key`. " normale Spaltenfarbe für Schlüsselfelder
    IF lv_theme CS 'hcw' OR lv_theme CS 'hcb' OR lv_theme CS 'dark'.
      lv_keycolor = `KeyHC`. " Spaltenfarbe für Schlüsselfelder in High Contrast oder dark modi
    ENDIF.

    " https://www.sap.com/design-system/fiori-design-web/v1-136/foundations/visual/colors/morning-horizon

    io_xml->_generic( name = `style`
                      ns   = `html`
       )->_cc_plain_xml( |td:has([data-color="Key"])\{ |
                      && |    background-color: #ccffff;| " quasi wie SAP-GUI
*                      && |    background-color: #A6E0FF;|  "sapIndicationColor_5
*                      && |    background-color: #E1F4FF;|  "Information Semantic Background
*                      && |    background-color: #E1F4FF;|  "Primary 2
*                      && |    background-color: @sapThemeHighlight-asBackgroundColor;|  "Primary 2

                      && |\}|
                      && |td:has([data-color="KeyHC"])\{|
                      && |    background-color: #0a6ed1;|
                      && |\}|
*        && ``
*        && `td:has([data-color="blue"]){`
*        && `    background-color: blue;`
*        && `}`
*        && ``
*        && `td:has([data-color="orange"]){`
*        && `    background-color: orange;`
*        && `}`
*        && ``
*        && `td:has([data-color="grey"]){`
*        && `    background-color: grey;`
*        && `}`
*        && ``
*        && `td:has([data-color="yellow"]){`
*        && `    background-color: yellow;`
*        && `}`
        ).

    DATA(lo_table) = io_xml->ui_table( alternaterowcolors = abap_true
*                                       id                 = |QP_F4_UITAB|
                                       rows               = ms_control-client->_bind_edit( mr_data->* )
                                       fixedcolumncount   = '1'
                                       selectionmode      = 'None'
*                                       selectionmode      = 'Single'
*                                       selectionbehavior  = 'Row'
                                       sort               = ms_control-client->_event( 'SORT' )
                                       filter             = ms_control-client->_event( 'FILTER' )
                                       rowselectionchange = ms_control-client->_event( 'SELECT' ) ).

    DATA(lo_columns) = lo_table->ui_columns( ).

    lo_columns->ui_column( width = '4rem' )->ui_template( )->checkbox( selected = `{F4_SEL}` ).

    DATA(lt_columns) = ms_shlp-fieldprop.
    SORT lt_columns BY shlplispos.
    DELETE lt_columns WHERE shlplispos = 0.

*    DATA(lv_lines) = lines( lt_columns ).

    DATA lt_desc  LIKE ms_shlp-fielddescr.

    DATA lv_total TYPE outputlen.
    " Spaltenbreiten bestimmen
    LOOP AT lt_columns ASSIGNING FIELD-SYMBOL(<col>).

      INSERT VALUE #( ms_shlp-fielddescr[ fieldname = <col>-fieldname ] OPTIONAL ) INTO TABLE lt_desc ASSIGNING FIELD-SYMBOL(<desc>).

      IF <desc>-outputlen < 12.
        <desc>-decimals = 12.
      ELSEIF <desc>-outputlen > 60.
        <desc>-decimals = 60.
      ELSE.
        <desc>-decimals = <desc>-outputlen.
      ENDIF.
      lv_total = lv_total + <desc>-decimals.

    ENDLOOP.
    " lv_total = Gesamtbreite in char der Zeile.
    " Jede Spalte hat eine Breite von  100 *<desc>-decimals/ lv_total %.

    LOOP AT lt_desc ASSIGNING <desc>.
      <desc>-masklen = 100 * <desc>-decimals / lv_total.

      IF <desc>-masklen > 20.
        DATA(lv_col_title) = <desc>-scrtext_l.
      ELSEIF <desc>-masklen > 8.
        lv_col_title = <desc>-scrtext_m.
      ELSE.
        lv_col_title = <desc>-scrtext_s.
      ENDIF.

      IF <desc>-mask+6(1) = 'X'.
        lo_columns->ui_column( sortproperty   = <desc>-fieldname
                               filterproperty = <desc>-fieldname
                               width          = |{ <desc>-masklen }%|
                               )->text( text = lv_col_title )->ui_template( )->checkbox( selected = |\{{ <desc>-fieldname }_CHECKBOX\}|
                                                                                         enabled  = abap_false ).

      ELSE.

        IF lt_columns[ fieldname = <desc>-fieldname ]-shlpoutput = abap_true.
          DATA(lv_color) = lv_keycolor.
        ELSE.
          lv_color = space.
        ENDIF.

        lo_columns->ui_column( sortproperty   = <desc>-fieldname
                               filterproperty = <desc>-fieldname
                               width          = |{ <desc>-masklen }%|

                               )->text( text = lv_col_title
* Background only for text, not the entire cell :-(
*                                        class = 'sapThemeBrand-asBackgroundColor'
*                                        class = 'sapThemeBarBG'
                                                            )->ui_template( )->text( text     = |\{{ <desc>-fieldname }\}|
                                                                                     wrapping = abap_false
                                                                                      )->get(
            )->custom_data(
              )->core_custom_data(
*                                   key        = 'class'
*                                   value      = 'sapThemeBrand-asBackgroundColor'
                                   key        = 'color'
                                   value      = lv_color
                                   writetodom = abap_true ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD class_constructor.
    SELECT SINGLE scrtext_l
      FROM dd04t
      INTO @ms_const-text_shlpname
      WHERE rollname = 'SHLPNAME' AND ddlanguage = @sy-langu.

    SELECT SINGLE scrtext_l
      FROM dd04t
      INTO @ms_const-text_tbmaxsel
      WHERE rollname = 'TBMAXSEL' AND ddlanguage = @sy-langu.
  ENDMETHOD.


  METHOD do_prepare_intf_selopt.
    " Fieldvalue in SHLP-interface
    IF ms_toe-value IS NOT INITIAL AND ms_toe-value CS '*'.
      LOOP AT cs_shlp-interface ASSIGNING FIELD-SYMBOL(<intf>)
           WHERE f4field IS NOT INITIAL.
        <intf>-value = ms_toe-value.
      ENDLOOP.
      IF sy-subrc <> 0.
        IF ms_toe-gruelm IS BOUND AND ms_toe-gruelm->tobel IS BOUND AND ms_toe-gruelm->tobel->shlp_fieldname IS NOT INITIAL.
          LOOP AT cs_shlp-interface ASSIGNING <intf>
               WHERE shlpfield = ms_toe-gruelm->tobel->shlp_fieldname.
            <intf>-value = ms_toe-value.
          ENDLOOP.
        ELSE.
          LOOP AT cs_shlp-fieldprop ASSIGNING FIELD-SYMBOL(<prop>)
               WHERE shlpinput = abap_true AND shlpoutput = abap_true.
            LOOP AT cs_shlp-interface ASSIGNING <intf>
                 WHERE shlpfield = <prop>-fieldname.
              <intf>-value = ms_toe-value.
            ENDLOOP.
            EXIT.
          ENDLOOP.
        ENDIF.
      ENDIF.

    ENDIF.

    " Defaults in SELOPT
    DATA(ls_callcontrol) = VALUE ddshf4ctrl( ).
    PERFORM map_interface_to_selopt IN PROGRAM saplsdsd CHANGING ls_callcontrol
                                                                 cs_shlp.

    " Vorbelegung der Suchfelder auf dem Popup
    LOOP AT cs_shlp-selopt ASSIGNING FIELD-SYMBOL(<selopt>)
         WHERE low IS NOT INITIAL.
      DATA(lr_selfield) = REF #( mt_selfields[ fieldname = <selopt>-shlpfield ] OPTIONAL ).
      IF  lr_selfield        IS BOUND
      AND lr_selfield->value IS INITIAL. " sonst werden die manuellen Eingaben nie berücksichtigt

        lr_selfield->value = <selopt>-low.
        conv_in2ex( EXPORTING is_dfies = cs_shlp-fielddescr[ fieldname = <selopt>-shlpfield ]
                    CHANGING  cv_value = lr_selfield->value ).

      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD do_build_out_table.
    " Eine dynamische Tabelle wird aufgebaut mit Feldlänge = outputlen ( spras = 2, datum = 10, usw )
    " IV_CHECK_FIELDPROP = X -> nur die sichtbaren Felder werden aufgenommen ( fieldprop-shlplispos > 0 )
    " IV_CHECK_FIELDPROP = space -> alle Felder aus IT_DESCR werden übernommen

    DATA lt_comp TYPE cl_abap_structdescr=>component_table.

    "  Die Logik zur Bestimmung der anzuzeigenden Spalten ist krank, insbesondere in diesen Fällen
    "  ACE_ACC_METHOD_CLASS
    " 1  DESCRIPTION D 0001  000060  AS4TEXT     SEODESCR
    " 2  CLASSNAME   D 0002  000000  SEOCLSNAME  ACE_ACCR_METHOD_CLASSNAME

    " oder ABRDATE_CUSTOMER
    " ABTYP    D 0001  000000
    " ABPAR    D 0002  000000
    " ABRDAT   D 0003  000000
    " ATYPETXT D 0004  000020
    " VABRDATE D 0005  000076
    " BOART    D 0006  000078
    " IDENT1   D 0007  000086
    " IDENT2   D 0008  000090
    " DATAB_SU D 0009  000000
    " DATBI_SU D 0010  000000
    " VTEXT    D 0011  000094

    " ALV_GRID_ID
    " ABRDATE_VENDOR
    " ABRDATE_*

    DATA(lt_descr) = it_descr.

    DO.
      READ TABLE lt_descr INDEX 1 INTO DATA(l1).
      READ TABLE lt_descr INDEX 2 INTO DATA(l2).
      IF sy-subrc = 0 AND l1-offset = 0 AND l2-offset = 0.
        DELETE lt_descr INDEX 1.
      ELSE.
        EXIT.
      ENDIF.
    ENDDO.
    SORT lt_descr BY offset.
    DELETE ADJACENT DUPLICATES FROM lt_descr COMPARING offset.

    LOOP AT lt_descr ASSIGNING FIELD-SYMBOL(<descr>).
*      DATA(index) = sy-tabix.
**      IF iv_check_fieldprop = abap_true.
**        " SH DEBIA :alle Felder aus fielddescr nicht in fieldprop -> OPTIONAL
**        IF VALUE #( ms_shlp-fieldprop[ fieldname = <descr>-fieldname ]-shlplispos OPTIONAL ) <= 0.
**          CONTINUE.
**        ENDIF.
**
**      ELSE.
*        " Die Felder mit dem gleich Offset (0) ausschließen
*        IF line_index( lt_descr[ offset = <descr>-offset ] ) < index.
** Vermutlich unnötig
*          CONTINUE.
*        ENDIF.
**      ENDIF.

      lt_comp = VALUE #( BASE lt_comp
                         ( name = <descr>-fieldname
                           type = cl_abap_elemdescr=>get_c( CONV #( <descr>-outputlen ) ) ) ).

      IF <descr>-mask+6(1) = 'X'. " Das Feld soll als Checkbox angezeigt werden
        INSERT |{ <descr>-fieldname }| INTO TABLE et_checkbox.
      ENDIF.

    ENDLOOP.

    IF lt_comp IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lo_struct) = cl_abap_structdescr=>create( p_components = lt_comp ).
    DATA(lo_table) = cl_abap_tabledescr=>create( p_line_type = lo_struct ).

    " mr_data_temp enthält alle Felder die in der Suchhilfe benötigt werden
    " mr_data enthält zusätzlich alle UI5 spezifischen Felder
    CREATE DATA mr_data_temp TYPE HANDLE lo_table.

    DATA lv_bool TYPE abap_bool.

    DATA(lr_bool) = CAST cl_abap_datadescr( cl_abap_datadescr=>describe_by_data( p_data = lv_bool ) ).

    " Eine Spalte dient als Selektionspalte
    INSERT VALUE #( name = 'F4_SEL'
                    type = lr_bool ) INTO TABLE lt_comp.

    " Um checkboxes sauber anzuzeigen braucht, man bools und kein char1 bzw. xfeld.
    " Dafür werden separate Spalten in mr_data aufgebaut
    LOOP AT et_checkbox ASSIGNING FIELD-SYMBOL(<line>).
      INSERT VALUE #( name = |{ <line> }_CHECKBOX|
                      type = lr_bool ) INTO TABLE lt_comp.
    ENDLOOP.

    lo_struct = cl_abap_structdescr=>create( p_components = lt_comp ).
    lo_table = cl_abap_tabledescr=>create( p_line_type = lo_struct ).

    CREATE DATA mr_data TYPE HANDLE lo_table.
  ENDMETHOD.


  METHOD do_button_cancel.
    ms_cb-cancelled = abap_true.
    ms_control-client->popup_destroy( ).
    ms_control-client->nav_app_leave( ms_control-client->get_app( ms_control-client->get( )-s_draft-id_prev_app_stack ) ).
  ENDMETHOD.


  METHOD do_button_confirm.
    CLEAR ms_cb-s_get-t_comp_params.
    FIELD-SYMBOLS <field> TYPE any.

    " SAPLSDSD
    "    perform transform_outval
    "            tables record_tab
    "                   flds_out_tab
    "            using callcontrol shlp_curr.
    "    perform map_interface_curr2top
    "            tables flds_out_tab
    "            using shlp_curr.

    ms_cb-cancelled = abap_false.
*    LOOP AT mr_data->* ASSIGNING FIELD-SYMBOL(<line>)
*         WHERE ('F4_SEL = abap_true').
*
*      DATA(col_count) = VALUE i( ).
*      " Zuerst das F4-Feld.
*      LOOP AT ms_shlp-interface ASSIGNING FIELD-SYMBOL(<intf>)
*           WHERE f4field IS NOT INITIAL.
*        ASSIGN COMPONENT <intf>-shlpfield OF STRUCTURE <line> TO <field>.
*        IF sy-subrc = 0.
*          INSERT VALUE #( n = <intf>-shlpfield
*                          v = CONV #( <field> ) )
*                 INTO TABLE ms_cb-s_get-t_comp_params.
*          col_count = col_count + 1.
*        ENDIF.
*      ENDLOOP.
*      " Dann alle anderen output-Felder
*
*      SORT ms_shlp-fieldprop BY shlplispos.
*      LOOP AT ms_shlp-fieldprop ASSIGNING FIELD-SYMBOL(<prop>)
*           WHERE shlpoutput = abap_true.
*        ASSIGN COMPONENT <prop>-fieldname OF STRUCTURE <line> TO <field>.
*        IF sy-subrc = 0 AND NOT line_exists( ms_cb-s_get-t_comp_params[ n = <prop>-fieldname ] ).
*
*          INSERT VALUE #( n = <prop>-fieldname
*                          v = CONV #( <field> ) )
*                 INTO TABLE ms_cb-s_get-t_comp_params.
*          col_count = col_count + 1.
*        ENDIF.
*      ENDLOOP.
*      IF col_count <> 0 AND NOT line_exists( ms_cb-named_params[ n = 'COL_COUNT' ] ).
*
*        INSERT VALUE #( n = 'COL_COUNT'
*                        v = col_count ) INTO TABLE ms_cb-named_params.
*      ENDIF.
*      IF mv_multi_allowed = abap_false.
*        EXIT.
*      ENDIF.
*
*    ENDLOOP.
    LOOP AT mr_data->* ASSIGNING FIELD-SYMBOL(<line>)
         WHERE ('F4_SEL = abap_true').

      INSERT INITIAL LINE INTO TABLE ms_cb-result_tab ASSIGNING FIELD-SYMBOL(<result>).

      " Zuerst das F4-Feld.
      LOOP AT ms_shlp-interface ASSIGNING FIELD-SYMBOL(<intf>)
           WHERE f4field IS NOT INITIAL.
        ASSIGN COMPONENT <intf>-shlpfield OF STRUCTURE <line> TO <field>.
        IF sy-subrc = 0.
          INSERT VALUE #( n = <intf>-shlpfield
                          v = CONV #( <field> ) )
                 INTO TABLE <result>.
        ENDIF.
      ENDLOOP.
      " Dann alle anderen output-Felder

      SORT ms_shlp-fieldprop BY shlplispos.
      LOOP AT ms_shlp-fieldprop ASSIGNING FIELD-SYMBOL(<prop>)
           WHERE shlpoutput = abap_true.
        ASSIGN COMPONENT <prop>-fieldname OF STRUCTURE <line> TO <field>.
        IF sy-subrc = 0 AND NOT line_exists( <result>[ n = <prop>-fieldname ] ).

          INSERT VALUE #( n = <prop>-fieldname
                          v = CONV #( <field> ) )
                 INTO TABLE <result>.
        ENDIF.
      ENDLOOP.

      IF mv_multi_allowed = abap_false.
        EXIT.
      ENDIF.

    ENDLOOP.

    IF sy-subrc = 0.
      " Popup schließen
      ms_control-client->popup_destroy( ).
      ms_control-client->nav_app_leave( ms_control-client->get_app( ms_control-client->get( )-s_draft-id_prev_app_stack ) ).
    ELSE.
      " Ohne Selektion bleibt das Popup stehen :Keine Auswahl vorhanden

      SELECT SINGLE text
        INTO @DATA(message)
        FROM t100
        WHERE sprsl = @sy-langu
          AND arbgb = '0K'
          AND msgnr = '205'.

      ms_control-client->message_toast_display( message ).
    ENDIF.
  ENDMETHOD.


  METHOD conv_ex2in.
    DATA lv_subrc TYPE sysubrc.

    PERFORM conversion_ex2in IN PROGRAM saplsdh4 IF FOUND USING    is_dfies
                                                                   ''
                                                          CHANGING cv_value
                                                                   lv_subrc.
  ENDMETHOD.


  METHOD conv_in2ex.
    PERFORM conversion_in2ex IN PROGRAM saplsdh4 IF FOUND USING    is_dfies
                                                                   ''
                                                          CHANGING cv_value.
  ENDMETHOD.


  METHOD do_fill_out_table.
    FIELD-SYMBOLS <table> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <line>  TYPE any.
    FIELD-SYMBOLS <fs>    TYPE any.
    FIELD-SYMBOLS <fs2>   TYPE any.

    do_build_out_table( EXPORTING it_descr    = it_descr
                        IMPORTING et_checkbox = DATA(lt_checkbox) ).

    IF mr_data_temp IS NOT BOUND OR mr_data IS NOT BOUND.
      " Keine vernünftige Tabellendefinition.
      RETURN.
    ENDIF.

    ASSIGN mr_data_temp->* TO <table>.
    " Daten der Suchhilfe in einer formatierten Tabelle kippen
    LOOP AT it_out ASSIGNING FIELD-SYMBOL(<val>).
      INSERT INITIAL LINE INTO TABLE <table> ASSIGNING <line>.
      <line> = <val>-string.
    ENDLOOP.

    MOVE-CORRESPONDING mr_data_temp->* TO mr_data->*.

    IF mr_data->* IS NOT INITIAL.
      mv_ok_active = abap_true.
    ENDIF.

    CLEAR mr_data_temp->*.
    FREE mr_data_temp.

    " UI5 Spalten befüllen
    IF lt_checkbox IS NOT INITIAL.
      " Alle Felder die als Checkbox angezeigt werden sollen
      " bekommen eine Zusatzspalte namens <FELDNNAME>_CHECKBOX als bool ( benötigt für UI5 )

      UNASSIGN : <table>, <line>.
      ASSIGN mr_data->* TO <table>.

      LOOP AT <table> ASSIGNING <line>.
        LOOP AT lt_checkbox ASSIGNING FIELD-SYMBOL(<field>).
          ASSIGN COMPONENT <field> OF STRUCTURE <line> TO <fs>.
          IF <fs> IS NOT INITIAL.
            ASSIGN COMPONENT |{ <field> }_CHECKBOX| OF STRUCTURE <line> TO <fs2>.
            <fs2> = abap_true.
          ENDIF.
        ENDLOOP.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.


  METHOD do_selfields_to_selopt.
    SORT ms_shlp-selopt.
    DELETE ADJACENT DUPLICATES FROM ms_shlp-selopt.

    LOOP AT mt_selfields ASSIGNING FIELD-SYMBOL(<sel>).

      IF <sel>-value IS NOT INITIAL.

        ASSIGN ms_shlp-interface[ shlpfield = <sel>-fieldname ] TO FIELD-SYMBOL(<intf>).
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.

        <intf>-value = <sel>-value.

        ASSIGN ms_shlp-selopt[ shlpfield = <sel>-fieldname ] TO FIELD-SYMBOL(<selopt>).
        IF sy-subrc <> 0.
          INSERT VALUE #( shlpname  = ms_shlp-shlpname
                          shlpfield = <sel>-fieldname )
                 INTO TABLE ms_shlp-selopt ASSIGNING <selopt>.
        ENDIF.

        do_set_selopt( EXPORTING iv_value  = <sel>-value
                       CHANGING  cs_selopt = <selopt> ).

      ELSEIF <sel>-token IS NOT INITIAL.
        DELETE ms_shlp-selopt WHERE shlpfield = <sel>-fieldname.
        LOOP AT <sel>-token ASSIGNING FIELD-SYMBOL(<token>).

          INSERT VALUE #( shlpname  = ms_shlp-shlpname
                          shlpfield = <sel>-fieldname )
                 INTO TABLE ms_shlp-selopt ASSIGNING <selopt>.
          do_set_selopt( EXPORTING iv_value  = <token>-key
                         CHANGING  cs_selopt = <selopt> ).
        ENDLOOP.
      ELSE.
        DELETE ms_shlp-selopt WHERE shlpfield = <sel>-fieldname.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD init_shlp.
    DATA lt_record_tab TYPE TABLE OF seahlpres.
    DATA lt_out        TYPE TABLE OF seahlpres.
    DATA lt_descr      TYPE TABLE OF dfies.
    DATA ls_callctrl   TYPE ddshf4ctrl.
    DATA ls_ocx        TYPE ddshocxint.

    /sct/qp_cl_factory=>get_instance( EXPORTING iv_classname = '/SCT/QP_CL_UI_TOE'
                                      CHANGING  co_instance  = mo_toe ).

    IF mo_toe IS BOUND.
      ms_toe = mo_toe->get_toe_structure( ms_toe ).
      DATA(lo_ui_toe) = CAST /sct/qp_cl_ui_toe( mo_toe ).
      lo_ui_toe->rebuild_context( CHANGING cs_toe = ms_toe ).

      /sct/qp_cl_sx_toe=>set_toe( io_toe = mo_toe
                                  is_toe = ms_toe ).

    ENDIF.

    " rs_shlp = top suchhilfe
    CALL FUNCTION 'F4IF_GET_SHLP_DESCR' EXPORTING shlpname = iv_shlp
                                        IMPORTING shlp     = rs_shlp.

    " Interface bei Bedarf erweitern.
    LOOP AT ms_cb-named_params ASSIGNING FIELD-SYMBOL(<param>).
      DATA(lr_intf) = REF #( rs_shlp-interface[ shlpfield = <param>-n ] OPTIONAL ).
      IF lr_intf IS BOUND.
        lr_intf->value = <param>-v.
      ENDIF.
      CLEAR lr_intf.
    ENDLOOP.
    DATA(lt_fieldprop) = rs_shlp-fieldprop.

    CALL FUNCTION 'DD_SHLP_GET_HELPMETHOD' EXPORTING  tabname     = space
                                                      fieldname   = space
*                                                      langu       = iv_logon_language
                                           CHANGING   shlp        = rs_shlp
                                                      callcontrol = ls_callctrl
                                           EXCEPTIONS OTHERS      = 0.

    CALL FUNCTION 'DD_SHLP_EXPAND_HELPMETHOD' EXPORTING  shlp_top = rs_shlp
                                              IMPORTING  shlp_tab = ms_coll_shlp-t_shlp
                                              EXCEPTIONS OTHERS   = 1.

    " top suchhilfe.
    ms_coll_shlp-shlp_descr = rs_shlp.

    " Because of SHLP Exits it is needed to call DD_SHLP_SINGLE_STEP multiple times
    ls_callctrl-step = 'SELONE'.
    " rs_shlp = ausgewählte Suchhilfe
    CALL FUNCTION 'DD_SHLP_SINGLE_STEP' TABLES   shlp_tab     = ms_coll_shlp-t_shlp
                                                 record_tab   = lt_record_tab
                                        CHANGING shlp_top     = ms_coll_shlp-shlp_descr
                                                 shlp_curr    = rs_shlp
                                                 callcontrol  = ls_callctrl
                                                 ocxinterface = ls_ocx.

    ls_callctrl-pvalues = 'D'.

    " Next step
    PERFORM f4proz_step_control IN PROGRAM saplsdsd USING    ms_coll_shlp-shlp_descr
                                                             ms_coll_shlp-t_shlp
                                                    CHANGING rs_shlp
                                                             ls_callctrl
                                                             ls_ocx.

    IF ls_callctrl-step <> 'PRESEL1'.
* Für Suchhilfen die falsch bzw unvollständig definiert sind...
*      BREAK-POINT.
    ENDIF.

    " Alle Rückgabefelder sind durch den EXIT gelöscht worden-> da kommt nie einen Wert zurück :-(
    " -> originale wiederherstellen
    LOOP AT lt_fieldprop ASSIGNING FIELD-SYMBOL(<prop>)
         WHERE shlpoutput = abap_true OR shlpinput = abap_true.
      ASSIGN rs_shlp-fieldprop[ fieldname = <prop>-fieldname ] TO FIELD-SYMBOL(<prop_target>).
      IF sy-subrc = 0.
        <prop_target>-shlpoutput = <prop>-shlpoutput.
        <prop_target>-shlpinput  = <prop>-shlpinput.
      ENDIF.
    ENDLOOP.

    do_prepare_intf_selopt( CHANGING cs_shlp = rs_shlp ).

    ls_callctrl-step = 'PRESEL1'.
    CALL FUNCTION 'DD_SHLP_SINGLE_STEP' TABLES   shlp_tab     = ms_coll_shlp-t_shlp
                                                 record_tab   = lt_record_tab
                                        CHANGING shlp_top     = ms_coll_shlp-shlp_descr
                                                 shlp_curr    = rs_shlp
                                                 callcontrol  = ls_callctrl
                                                 ocxinterface = ls_ocx.

    " Next step
    PERFORM f4proz_step_control IN PROGRAM saplsdsd USING    ms_coll_shlp-shlp_descr
                                                             ms_coll_shlp-t_shlp
                                                    CHANGING rs_shlp
                                                             ls_callctrl
                                                             ls_ocx.

    IF ls_callctrl-step = 'TSTSEL'.
      " Dialog = 'A'. Selektion anhand Anz. Datensätze
      CALL FUNCTION 'DD_SHLP_SINGLE_STEP' TABLES   shlp_tab     = ms_coll_shlp-t_shlp
                                                   record_tab   = lt_record_tab
                                          CHANGING shlp_top     = ms_coll_shlp-shlp_descr
                                                   shlp_curr    = rs_shlp
                                                   callcontrol  = ls_callctrl
                                                   ocxinterface = ls_ocx.

      PERFORM f4proz_step_control IN PROGRAM saplsdsd USING    ms_coll_shlp-shlp_descr
                                                               ms_coll_shlp-t_shlp
                                                      CHANGING rs_shlp
                                                               ls_callctrl
                                                               ls_ocx.

    ENDIF.

    IF ls_callctrl-step = 'PRESEL'.
      " Keine sofortige selektion.
      mv_immediate_selection = abap_false.
    ELSE. " SELECT,DISP,EXIT
      mv_immediate_selection = abap_true.
    ENDIF.

    " Alle Rückgabefelder sind durch den EXIT gelöscht worden-> da kommt nie einen Wert zurück :-(
    " -> originale wiederherstellen
    LOOP AT lt_fieldprop ASSIGNING <prop>
         WHERE shlpoutput = abap_true.
      ASSIGN rs_shlp-fieldprop[ fieldname = <prop>-fieldname ] TO <prop_target>.
      IF sy-subrc = 0.
        <prop_target>-shlpoutput = abap_true.
      ENDIF.
    ENDLOOP.

    IF mv_maxrows IS INITIAL.
      mv_maxrows = ls_callctrl-maxrecords.
    ENDIF.

    " Ausgabe Tabelle bestimmen
    CALL FUNCTION 'F4IF_CONVERSION_IN2EX' TABLES records_in   = lt_record_tab
                                                 recdescr_in  = rs_shlp-fielddescr
                                                 records_out  = lt_out
                                                 recdescr_out = lt_descr.

    " Notwendig für do_display() wegen Binding
    do_build_out_table( lt_descr ).
  ENDMETHOD.


  METHOD popup_error.
    SELECT SINGLE text
      INTO @DATA(title)
      FROM t100
      WHERE sprsl = @sy-langu
        AND arbgb = 'SSC_CUST'
        AND msgnr = '022'.

    DATA(popup) = /sct/au5_cl_xml_view=>factory_popup( ).
    popup->dialog( title
            )->vbox(
                )->text( iv_msg
            )->get_parent(
                )->buttons(
                )->button( text  = mutx->get_text( mutx->u034 )
                           press = ms_control-client->_event( 'BUTTON_CANCEL' )
                           type  = 'Emphasized' ).

    ms_control-client->popup_display( popup->stringify( ) ).
  ENDMETHOD.


  METHOD do_set_selopt.
    " 1 - Ermittlung der Select-option :  >= wird I GE
    "                                     <  wird I LT
    "                                     != wird E EQ  , usw.
    " 2 - Konvertierung ins internen Format

    DATA(lv_value) = iv_value.
    SHIFT lv_value LEFT DELETING LEADING space.

    " *********************************************************************
    " SIGN
    " *********************************************************************
    IF lv_value(1) = '!'.
      cs_selopt-sign = mc->sign_e.
      lv_value = lv_value+1.
    ELSE.
      cs_selopt-sign = mc->sign_i.
    ENDIF.

    " *********************************************************************
    " OPTION + LOW
    " *********************************************************************
    IF strlen( lv_value ) > 2 AND lv_value(2) CO '=<>'.
      cs_selopt-low = lv_value+2.
      IF lv_value(2) = '>=' OR lv_value(2) = '=>'.
        cs_selopt-option = mc->option_ge.
      ELSEIF lv_value(2) = '<=' OR lv_value(2) = '=<'.
        cs_selopt-option = mc->option_le.
      ELSEIF lv_value(2) = '<>' OR lv_value(2) = '><'.
        cs_selopt-option = mc->option_ne.
      ELSE.
        BREAK-POINT.
      ENDIF.

    ELSEIF strlen( lv_value ) > 1 AND lv_value(1) CO '=<>'.
      cs_selopt-low = lv_value+1.
      IF lv_value(1) = '>'.
        cs_selopt-option = mc->option_gt.
      ELSEIF lv_value(1) = '<'.
        cs_selopt-option = mc->option_lt.
      ELSEIF lv_value(1) = '='.
        IF lv_value CS '*'.
          cs_selopt-option = mc->option_cp.
        ELSE.
          cs_selopt-option = mc->option_eq.
        ENDIF.
      ELSE.
        BREAK-POINT.
      ENDIF.
    ELSE.
      cs_selopt-low = lv_value.
      IF lv_value CS '*'.
        cs_selopt-option = mc->option_cp.
      ELSE.
        cs_selopt-option = mc->option_eq.
      ENDIF.
    ENDIF.

    " EXT -> INT conversion
    conv_ex2in( EXPORTING is_dfies = ms_shlp-fielddescr[ fieldname = cs_selopt-shlpfield ]
                CHANGING  cv_value = cs_selopt-low ).
  ENDMETHOD.


  METHOD /sct/qp_if_ui_searchhelp~get_data.
    ms_shlp = init_shlp( ms_shlp-shlpname ).
    DATA lt_result TYPE /sct/qp_qv_search_result_tt.
    DATA lv_value  TYPE fieldname.
    DATA lv_ktxt   TYPE fieldname.
    DATA(lt_prop) = ms_shlp-fieldprop.
    SORT lt_prop BY shlplispos ASCENDING.
    LOOP AT lt_prop ASSIGNING FIELD-SYMBOL(<prop>)
         WHERE shlpoutput = abap_true AND shlplispos > 0.
      IF lv_value IS NOT INITIAL AND lv_ktxt IS INITIAL.
        lv_ktxt = <prop>-fieldname.
      ENDIF.
      IF lv_value IS INITIAL.
        lv_value = <prop>-fieldname.
      ENDIF.
    ENDLOOP.

*    IF lv_ktxt IS INITIAL.
    DATA(lt_fielddescr) = ms_shlp-fielddescr.
    SORT lt_fielddescr BY leng DESCENDING.
    lv_ktxt = lt_fielddescr[ 1 ]-fieldname.
    IF lv_ktxt <> lv_value.
      ms_shlp-fieldprop[ fieldname = lv_ktxt ]-shlpoutput = abap_true.
    ELSE.
      CLEAR lv_ktxt.
    ENDIF.
*    ENDIF.

    " Try to get the value description in the table ( assuming it's the longest field ).

    CALL FUNCTION 'F4IF_SELECT_VALUES' EXPORTING shlp           = ms_shlp                " Suchhilfe-Beschreibung
*                                                 maxrows        = 0                " <>0: Zeilenbeschränkung für RECORD_TAB
*                                                 sort           = space            " Sortierte Ausgabe. (Achtung Performance!)
                                                 call_shlp_exit = abap_true           " Suchhilfe-Exit für SELECT durchlaufen, falls vorhanden
*     IMPORTING
*                                                 maxrows_exceeded = " X: RECORD_TAB auf MAXROWS Einträge beschränkt
                                       TABLES
*                                                 record_tab     = " nicht mehr verwenden
*                                                 recdescr_tab   = " nicht mehr verwenden
                                                 return_tab     = lt_result.                  " Rückgabe der ausgewählten Werte

    " Mapping
    LOOP AT lt_result ASSIGNING FIELD-SYMBOL(<result>) GROUP BY <result>-recordpos ASSIGNING FIELD-SYMBOL(<group>).
      INSERT INITIAL LINE INTO TABLE result ASSIGNING FIELD-SYMBOL(<data>).
      LOOP AT GROUP <group> ASSIGNING FIELD-SYMBOL(<record>).
        IF <record>-fieldname = lv_value.
          <data>-element = lv_value.
          <data>-value   = <record>-fieldval.
        ELSEIF <record>-fieldname = lv_ktxt.
          <data>-ktxt = <record>-fieldval.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
