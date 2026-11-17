class /SCT/QP_CL_UI_TEXT definition
  public
  inheriting from /SCT/QP_CL_UI_OBJTYP
  create public .

public section.

  interfaces IF_SERIALIZABLE_OBJECT .

  types:
    BEGIN OF ty_spras,
        spras TYPE sylangu,
        laiso TYPE laiso,
        sptxt TYPE sptxt,
        descr TYPE string,
      END OF ty_spras .
  types:
    tty_spras TYPE STANDARD TABLE OF ty_spras WITH DEFAULT KEY .
  types:
    BEGIN OF ty_sel,
        mamba_sel TYPE abap_bool,
        rowid     TYPE /sct/qp_rowid,
      END OF ty_sel .
  types:
    tty_sel TYPE STANDARD TABLE OF ty_sel WITH DEFAULT KEY .
  types:
    BEGIN OF ty_sug,
        selkz TYPE abap_bool,
        value TYPE string,
        descr TYPE string,
      END OF ty_sug .
  types:
    tty_sug TYPE SORTED TABLE OF ty_sug WITH UNIQUE KEY value .
  types:
    BEGIN OF elem_sug,
        element TYPE string,
        sug_tab TYPE tty_sug,
      END OF elem_sug .
  types:
    tty_elem_sug TYPE STANDARD TABLE OF elem_sug WITH DEFAULT KEY .
  types:
    BEGIN OF s_suggestion_items,
        selkz TYPE abap_bool,
        value TYPE string,
        descr TYPE string,
      END OF s_suggestion_items .
  types:
    BEGIN OF tty_texttable,
        selkz     TYPE abap_bool,
        tdobject  TYPE tdobject,
        tdid      TYPE tdid,
        tdid_text TYPE string,
        tdspras   TYPE spras,
        lang      TYPE laiso,
        lang_text TYPE string,
        data      TYPE /sct/qp_s_qvc_stx_data,
        text      TYPE /sct/qp_stx_text,
        new       TYPE abap_bool,
        sortnr    TYPE /sct/qp_sortnr,
      END OF tty_texttable .

  data MS_FCAT type /SCT/QP_S_FCAT .
  data MV_EDIT type ABAP_BOOLEAN .
  data MT_SUG type TTY_ELEM_SUG .
  data MT_TEXT type /SCT/QP_T_TEXT .
  data:
    mt_text_table TYPE STANDARD TABLE OF tty_texttable .
  data MT_SPRAS type TTY_SPRAS .

  methods CONSTRUCTOR
    importing
      !IS_OBJ type /SCT/QP_IF_UI_OBJTYP=>TY_S_OBJTYP optional .
  methods ADD_TEXT .
  methods DELETE_TEXT .
  methods POST_TEXT .

  methods /SCT/QP_IF_UI_APP~ACTUALIZE_BINDINGS
    redefinition .
  methods /SCT/QP_IF_UI_APP~DISPLAY
    redefinition .
  methods /SCT/QP_IF_UI_APP~INIT
    redefinition .
  methods /SCT/QP_IF_UI_OBJTYP~CHECK_CHANGES
    redefinition .
protected section.

  data MO_TEXT type ref to /SCT/QP_IF_TEXT .
  data MT_TDID type /SCT/QP_THT_TDID .

    "! <p class="shorttext synchronized"></p>
    "! Kontextabhängig, werden unterschiedlichen Drucktasten zur Verfügung gestellt
    "! @parameter IO_VIEW | <p class="shorttext synchronized"></p>
  methods SET_TOOLBAR
    importing
      !IO_VIEW type ref to /SCT/AU5_CL_XML_VIEW .
  methods DO_SHOW_TEXT .
    "! <p class="shorttext synchronized"></p>
    "!
    "! @parameter IS_GET       | <p class="shorttext synchronized"></p>
    "! @parameter RV_PROCESSED | <p class="shorttext synchronized"></p>
  methods PROCESS_EVENT                                                                    " AD, 2026.10.09, changed
    importing
      !IS_GET type /SCT/AU5_IF_CLIENT=>TY_S_GET
    returning
      value(RV_PROCESSED) type ABAP_BOOL .
    "! <p class="shorttext synchronized"></p>
    "!
    "! @parameter STATEFUL | <p class="shorttext synchronized"></p>
  methods SET_SESSION_STATEFUL
    importing
      !STATEFUL type ABAP_BOOL .

  methods INIT
    redefinition .
  methods PROCESS_FCODE_SELF
    redefinition .
  PRIVATE SECTION.

ENDCLASS.



CLASS /SCT/QP_CL_UI_TEXT IMPLEMENTATION.


  METHOD /sct/qp_if_ui_app~display.
*    get_objtyp_data( ).
    ms_control-parent_view = io_view.
    ms_control-client      = io_client.

    do_show_text( ).
  ENDMETHOD.


  METHOD /sct/qp_if_ui_app~init.
    super->/sct/qp_if_ui_app~init( is_control = is_control ).
    init( ms_control-client ).
  ENDMETHOD.


  METHOD /sct/qp_if_ui_objtyp~check_changes.
    IF mv_bound = abap_false.
      RETURN.
    ENDIF.
    post_text( ).
    /sct/qp_if_ui_app~actualize_bindings( ).
*    LOOP AT mt_text ASSIGNING FIELD-SYMBOL(<text>).
*
*      mo_tools->do_convert_string_to_text( EXPORTING iv_string = <text>-data_ref->stx_text
*                                           IMPORTING et_tline  = DATA(lt_tline) ).
*      mo_text->process( is_data = VALUE #( action = mc->action_update
*                                           stx    = VALUE #( BASE <text>-data_ref->*
*                                                             tline = lt_tline ) ) ).
*    ENDLOOP.
  ENDMETHOD.


  METHOD constructor.
    super->constructor( is_obj ).
*    IF is_obj IS NOT INITIAL.
*      ms_obj = is_obj.
*    ELSE.
*      start_standalone = abap_true.
*    ENDIF.
  ENDMETHOD.


  METHOD do_show_text.
    TRY.
        " View erstellen
        DATA(lo_view) = ms_control-parent_view.
        lo_view = ms_control-parent_view->scroll_container( " height     = '70%'
                                                            width      = '100%'
*                                                            vertical   = abap_true
                                                            horizontal = abap_true ).

        " Variable für Tabellenselektionsmodus abhängig von der editierbarkeit
        DATA(lv_edit) = is_editable( ).
        DATA lv_selmode TYPE string.
        IF lv_edit = abap_true.
          lv_selmode = 'MultiSelect'.
        ELSE.
          lv_selmode = 'None'.
        ENDIF.

        " Texttabelle erstellen
        " TODO: variable is assigned but only used in commented-out code (ABAP cleaner)
        " TODO: variable is assigned but never used (ABAP cleaner)
        DATA(lo_table) = lo_view->table( alternaterowcolors = abap_true
                                         id                 = |TAB{ ms_node_object-objekttyp }|

                                         items              = |\{path:'{ ms_control-client->_bind( val  = mt_text_table
*                                                                                                   ir_data = REF #( mt_text_table )
                                                                                                   path = abap_true ) }', sorter:\{ path: 'TDID_TEXT', descending: false, group: true \}\}| ", groupHeaderFactory: '.getGroupHeader' \}|
*                                         iv_path            = abap_true ) }', sorter:\{ path: 'SORTNR', descending: false, group: \{ key: 'SORTNR', text: 'TDID_TEXT' \} \}\}| ", groupHeaderFactory: '.getGroupHeader' \}|
*                                         iv_path            = abap_true ) }', sorter:\{ path: \{ key: 'TDID_TEXT', text: 'TDID_TEXT' \}, descending: false, group: true \}\}| ", groupHeaderFactory: '.getGroupHeader' \}|
*                                         iv_path            = abap_true ) }', sorter:\{ path: 'TDID_TEXT', descending: false, group: \{ key: 'SORTNR', text: 'TDID_TEXT' \}, groupHeaderFactory: '.getGroupHeader' \}\}|
*                                         iv_path            = abap_true ) }', sorter:\{ path: 'TDID_TEXT', descending: false, group: true  \} \}, groupHeaderFactory: '.getGroupHeader' \}|
*                                         iv_path            = abap_true ) }', sorter:\{ path: 'SORTNR', descending: false, group: true \} , groupHeaderFactory: '.getGroupHeader' \}|

**                                         iv_path            = abap_true ) }', sorter:\{ path: 'SORTNR', descending: false, group: true \} , groupHeaderFactory:  'TDID_TEXT' \}|

*                                         items              = _bind( iv_edit = lv_edit
*                                         ir_data            = REF #( mt_text_table ) )

                                         mode               = |{ lv_selmode }|
*                                         width              = lv_table_width
                                         " Tabellenkopf mit Buttons
                                                                                  )->header_toolbar(
                                                                                  )->overflow_toolbar(
*                                                                                  )->button( text    = 'ADD'
*                                                                                             visible = lv_edit
*                                                                                             icon    = 'sap-icon://add'
*                                                                                             press   = _event( iv_name = 'TEXT_ADD' )
                                                                                  )->button( text    = mtx->get_text( 'TBB' )
                                                                                             visible = lv_edit
                                                                                             icon    = 'sap-icon://delete'
                                                                                             press   = _event( iv_name = 'TEXT_DELETE' )
                                                                                  )->get_parent( )->get_parent(
                                                                                                                " Tabellenspalten definieren
                                                                                                                )->columns(
*                                                                        )->column( halign = 'Left'
*                                                                                   width  = '15%'
*                                                                        )->text( text     = 'ID'
*                                                                                 wrapping = abap_false
*                                                                                         )->get_parent(
                                                                        )->column( halign = 'Center' "'Left'
                                                                                   width  = '20%'
                                                                        )->text( text = mutx->get_text( mutx->n107 ) " Sprache
                                                                                         )->get_parent(
                                                                        )->column( halign = 'Center'                " Inhalt
                                                                                   width  = '80%'
                                                                        )->text( text = mutx->get_text( mutx->n108 ) )->get_parent( )->get_parent(
                                                                                                                                                   " Tabelleneinträge binden
                                                                                                                                                   )->items(
                                                   )->column_list_item( selected = '{SELKZ}'
                                                   )->cells(
*                                                   )->input( value    = '{TDID_TEXT}'
*                                                             required = abap_true
*                                                             editable = '{NEW}'
**                                                             autocomplete = lv_edit
                                                   )->input( value            = '{LANG_TEXT}'
                                                             required         = abap_true
                                                             editable         = '{NEW}'
*                                                             autocomplete     = lv_edit
                                                             showsuggestion   = lv_edit
                                                             suggestionitems  = ms_control-client->_bind( mt_spras )
                                                             showvaluehelp    = abap_true
                                                             valuehelprequest = _event( iv_name = 'POPUP_F4'
                                                                                        it_arg  = VALUE #( BASE mt_def_arg
*                                                                                                           ( `TEST`  )
                                                                                                           ( `${TDID}`  )
*                                                                                                           ( `${TDSPRAS}` )
                                                                                                           ) )
                                                   )->get(
                                                   )->suggestion_items(
                                                   )->get(
                                                   )->list_item( text           = `{LAISO}`
                                                                 additionaltext = `{SPTXT}`
                                                   )->get_parent( )->get_parent( )->text_area( value           = '{TEXT}'
                                                                                               valueliveupdate = abap_true
                                                                                               growing         = abap_true
                                                                                               growingmaxlines = '7'
                                                                                               width           = '100%'
                                                                                               placeholder     = mutx->get_text( mutx->n108 )
                                                                                               editable        = lv_edit ).

      CATCH cx_root.
    ENDTRY.
  ENDMETHOD.


  METHOD init.
    ms_control-client = client.
    mo_text ?= ms_obj-object.

    /sct/qp_cl_factory=>get_instances( IMPORTING eo_const = mc
                                                 eo_conv  = mo_conv ).

    CLEAR mt_spras.
    mo_cust->get_tspras( IMPORTING et_tspras = DATA(lt_spras) ).

    LOOP AT lt_spras ASSIGNING FIELD-SYMBOL(<ls_tspras>) USING KEY sortnr_spras.
      DATA(ls_spras) = CORRESPONDING ty_spras( <ls_tspras> ).

*      " CleanCore
      SELECT SINGLE LanguageISOCode
        FROM i_language
        WHERE Language = @ls_spras-spras
        INTO @ls_spras-laiso.
      ls_spras-descr = |{ ls_spras-sptxt } ({ ls_spras-laiso })|.

      INSERT ls_spras INTO TABLE mt_spras.

    ENDLOOP.

    /sct/qp_if_ui_app~actualize_bindings( ).
    "
  ENDMETHOD.


  METHOD process_event.
    rv_processed = is_event_relevant( is_get ).
    IF rv_processed = abap_false.
      RETURN.
    ENDIF.

    CASE is_get-event.

      WHEN 'TEXT_POST'.
        " check_changes( ).
        post_text( ).

        rv_processed = abap_true.

*      WHEN 'TEXT_ADD'.
*        add_text( ).

      WHEN 'F4_BACK'.
        FIELD-SYMBOLS <ls_params> TYPE /sct/au5_if_types=>ty_s_name_value.

        ASSIGN mt_text_table[ new  = abap_true
                              tdid = CONV #( is_get-t_event_arg[ 4 ] ) ] TO FIELD-SYMBOL(<ls_text>).
        IF sy-subrc <> 0.
          RETURN.
        ENDIF.

        IF is_get-r_event_data IS BOUND.

          LOOP AT is_get-r_event_data->* ASSIGNING FIELD-SYMBOL(<result>). " Tabelle fon Ergebnistabellen (Mehfachselektion Suchhilfe)
            LOOP AT <result> ASSIGNING <ls_params>.

              IF <ls_params>-n = mc->element_spras.
                <ls_text>-lang_text = <ls_params>-v.
                <ls_text>-lang      = <ls_params>-v.

                " CleanCore
                <ls_text>-tdspras   = mt_spras[ laiso = <ls_text>-lang_text ]-spras.

*                CALL FUNCTION 'CONVERSION_EXIT_ISOLA_INPUT' EXPORTING  input            = <ls_text>-lang_text  " DE
*                                                            IMPORTING  output           = <ls_text>-tdspras " D
*                                                            EXCEPTIONS unknown_language = 1
*                                                                       OTHERS           = 2 ##FM_SUBRC_OK.

                EXIT.
              ENDIF.

*                  IF NOT line_exists( <uiattr>-token[ key = <ls_params>-v ] ).
*                    " Doppelte Einträge vermeiden.
**                    INSERT VALUE #( key      = <ls_params>-v
**                                    text     = <ls_params>-v
**                                    visible  = abap_true
**                                    editable = abap_true ) INTO TABLE <uiattr>-token.
*                    INSERT VALUE #( key      = <ls_params>-v
*                                    text     = <ls_params>-v
*                                    visible  = abap_true
*                                    editable = abap_true ) INTO TABLE <uiattr>-token_add.
*                  ENDIF.

            ENDLOOP.
          ENDLOOP.

        ENDIF.

      WHEN 'TEXT_DELETE'.
        delete_text( ).

      WHEN 'POPUP_F4'.
        DATA(mo_ui_f4) = /sct/qp_cl_ui_searchhelp=>get_instance( ).
        mo_ui_f4->init( iv_shlp     = '/SCT/QP_SH_SPRAS'
                        is_callback = VALUE #( s_get-event       = 'F4_BACK'
                                               s_get-t_event_arg = is_get-t_event_arg ) ).
        ms_control-client->nav_app_call( CAST /sct/au5_if_app( mo_ui_f4 ) ).

      WHEN OTHERS.
*
*        DATA(ls_action) = VALUE /sct/qp_s_mamba_action( action = is_get-event ).
*        mt_sel = CORRESPONDING #( ms_fcat-data->* ).
*        DELETE mt_sel WHERE mamba_sel IS INITIAL.
*        LOOP AT mt_sel ASSIGNING FIELD-SYMBOL(<sel>).
*          INSERT <sel>-rowid INTO TABLE ls_action-rows.
*        ENDLOOP.
*
*        mo_mamba->process( ir_base   = ms_obj-base
*                           is_action = ls_action ).

    ENDCASE.
  ENDMETHOD.


  METHOD process_fcode_self.
    rv_processed = process_event( is_get ).
  ENDMETHOD.


  METHOD set_session_stateful.
    ms_control-client->set_session_stateful( stateful ).
    ms_control-client->view_model_update( ).
  ENDMETHOD.


  METHOD set_toolbar.
  ENDMETHOD.


  METHOD add_text. " Neue Zeile erstellen
*    INSERT VALUE #( tdid     = ''
*                    lang   = ''
*                    tdobject = '/SCT/QP'
*                    data   = VALUE #( )
*                    new    = abap_true )
*           INTO TABLE mt_text_table.
  ENDMETHOD.


  METHOD delete_text. " Zeile löschen
*    DATA(ls_entry) = mt_text_table[ selkz = abap_true ].

    LOOP AT mt_text_table ASSIGNING FIELD-SYMBOL(<entry>)
         WHERE selkz = abap_true.

*      TRY.
      mo_text->process( is_data = VALUE #( action       = mc->action_delline
                                           stx-guid     = <entry>-data-guid
                                           stx-tdobjekt = <entry>-tdobject
                                           stx-tdname   = <entry>-data-tdname
                                           stx-tdid     = <entry>-tdid
                                           stx-tdspras  = <entry>-tdspras ) ).
*        CATCH /sct/qp_cx_error.
*      ENDTRY.

    ENDLOOP.

    DELETE mt_text_table WHERE selkz = abap_true.
  ENDMETHOD.


  METHOD post_text.
    TRY.

        " Mögliche Sprachen erfragen
*        mo_cust->get_tspras( IMPORTING et_tspras = DATA(lt_spras) ).
*
*        " Mögliche IDs erfragen
*        mo_cust->get_tdid( EXPORTING iv_objekttyp     = mo_text->ms_node_object-objekttyp
*                                     iv_elementgruppe = mo_text->ms_node_object-elementgruppe
*                           IMPORTING et_tdid          = DATA(lt_tdid) ).

        " Jeden Eintrag checken
        LOOP AT mt_text_table ASSIGNING FIELD-SYMBOL(<fstext>).

          IF <fstext>-new IS NOT INITIAL.

            " UI Ausgabe für Backend konvertieren

            " CleanCore
            <fstext>-tdspras = VALUE #( mt_spras[ laiso = <fstext>-lang_text ]-spras OPTIONAL ).

*            CALL FUNCTION 'CONVERSION_EXIT_ISOLA_INPUT' EXPORTING  input            = <fstext>-lang_text " DE
*                                                        IMPORTING  output           = <fstext>-tdspras " D
*                                                        EXCEPTIONS unknown_language = 1
*                                                                   OTHERS           = 2 ##FM_SUBRC_OK.
          ENDIF.

          IF <fstext>-tdspras IS NOT INITIAL.
            " Text Zeilenweise konvertieren
            mo_tools->do_convert_string_to_text( EXPORTING iv_string = <fstext>-text
                                                 IMPORTING et_tline  = DATA(lt_tline) ).

            " Gibt es die Sprache und das Objekt?
            IF  line_exists( mt_spras[ spras = <fstext>-tdspras  ] )
            AND line_exists( mt_tdid[ tdid = <fstext>-tdid  ] ).

              " Gibt es ein identisches Objekt?
              " Wenn ja, update das bestehende Element
              IF line_exists( mo_text->mt_text[ tdid    = <fstext>-tdid
                                                tdspras = <fstext>-tdspras ] ).

                mo_text->process( is_data = VALUE #( action = mc->action_change
                                                     stx    = VALUE #( BASE <fstext>-data
                                                                       tline = lt_tline ) ) ).
*                                                   stx-guid     = mo_text->mo_parent->ms_base-guid
*                                                   stx-tdobjekt = <fstext>-objtyp
*                                                   stx-tdid     = <fstext>-id
*                                                   stx-tdspras  = <fstext>-lang ) ).
              " Wenn nein, lege ein neues Element an
              ELSE.
                mo_text->process( is_data = VALUE #( action = mc->action_insert
                                                     stx    = VALUE #( BASE <fstext>-data
                                                                       tline    = lt_tline
                                                                       guid     = mo_text->mo_parent->ms_base-guid
                                                                       tdobjekt = <fstext>-tdobject
                                                                       tdid     = <fstext>-tdid
                                                                       tdspras  = <fstext>-tdspras ) ) ).
              ENDIF.
            ELSE.
              " Eintrag nicht möglich
            ENDIF.

          ELSE.
            do_show_message( it_return  = VALUE #( ( message = 'Unknown language.' ) )
                             iv_msgtype = 'E' ).
          ENDIF.
        ENDLOOP.

      CATCH /sct/qp_cx_error.
    ENDTRY.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_app~actualize_bindings.
    mo_cust->get_tdid( EXPORTING iv_objekttyp     = mo_text->ms_node_object-objekttyp
                                 iv_elementgruppe = mo_text->ms_node_object-elementgruppe
                       IMPORTING et_tdid          = mt_tdid ).

    CLEAR mt_text_table.

    " Ausgabeformat für UI aendern und Daten in neue Tabelle schreiben
    LOOP AT mo_text->mt_text ASSIGNING FIELD-SYMBOL(<fstxt>) GROUP BY ( tdid = <fstxt>-tdid
                                                                        size = GROUP SIZE ) REFERENCE INTO DATA(lr_group).

      LOOP AT GROUP lr_group ASSIGNING <fstxt>.

        ASSIGN mt_spras[ spras = <fstxt>-tdspras ] TO FIELD-SYMBOL(<ls_spras>).

        ASSIGN mt_tdid[ tdid = <fstxt>-tdid ] TO FIELD-SYMBOL(<ls_tdid>).

        APPEND VALUE #( tdobject  = <fstxt>-tdobject
                        tdid      = <fstxt>-tdid
                        tdid_text = |{ <ls_tdid>-tdtext } ({ <ls_tdid>-tdid })|
                        tdspras   = <fstxt>-tdspras
                        lang      = <ls_spras>-laiso
                        lang_text = <ls_spras>-descr
                        data      = <fstxt>-data_ref->*
                        text      = <fstxt>-data_ref->stx_text
                        new       = abap_false
                        sortnr    = <ls_tdid>-sortnr )
               TO mt_text_table.
      ENDLOOP.

      IF lr_group->size <> lines( mt_spras ) AND is_editable( ) = abap_true.
        " Anlage neue Sprache möglich.
        ASSIGN mt_tdid[ tdid = lr_group->tdid ] TO <ls_tdid>.

        APPEND VALUE #( tdobject  = <ls_tdid>-tdobject
                        tdid      = <ls_tdid>-tdid
                        tdid_text = |{ <ls_tdid>-tdtext } ({ <ls_tdid>-tdid })|
                        data      = VALUE #( )
                        new       = abap_true
                        sortnr    = <ls_tdid>-sortnr )
               TO mt_text_table.
      ENDIF.
    ENDLOOP.

    " Nach Sortnr TD und laiso sortieren
    SORT mt_text_table BY sortnr
                          new
                          lang.

    _bind( iv_fieldname = |mt_text_table| ).
    _bind( iv_fieldname = |mt_spras| ).
    super->/sct/qp_if_ui_app~actualize_bindings( ).
  ENDMETHOD.
ENDCLASS.
