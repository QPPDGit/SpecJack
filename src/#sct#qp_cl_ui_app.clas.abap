CLASS /sct/qp_cl_ui_app DEFINITION
  PUBLIC
  INHERITING FROM /sct/qp_cl_gts ABSTRACT
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES /sct/qp_if_ui_app.

    ALIASES mcu           FOR /sct/qp_if_ui_app~mcu.
    ALIASES mo_ui_handler FOR /sct/qp_if_ui_app~mo_ui_handler.
    ALIASES mt_sub_app    FOR /sct/qp_if_ui_app~mt_sub_app.
    ALIASES mutx          FOR /sct/qp_if_ui_app~mutx.
    ALIASES is_stateful   FOR /sct/qp_if_ui_app~is_stateful.
    ALIASES set_stateful  FOR /sct/qp_if_ui_app~set_stateful.

    METHODS constructor.

  PROTECTED SECTION.
    ALIASES ms_control FOR /sct/qp_if_ui_app~ms_control.

    DATA mv_sub_app_index TYPE i.
    DATA mt_def_arg       TYPE string_table.
    DATA ms_callback      TYPE /sct/qp_if_ui_callback=>ty_s_callback.
    DATA mv_bound         TYPE abap_boolean.

    "! <p class="shorttext synchronized">process own events</p>
    "!
    "! @parameter is_get       | <p class="shorttext synchronized"></p>
    "! @parameter rv_processed | <p class="shorttext synchronized"></p>
    METHODS process_fcode_self                                                                         " AD, 2026.10.09, changed
                               IMPORTING is_get              TYPE /sct/au5_if_client=>ty_s_get
                               RETURNING VALUE(rv_processed) TYPE abap_bool
                               RAISING   /sct/qp_cx_error.

    "! <p class="shorttext synchronized">pass down events to sub-applications</p>
    "!
    "! @parameter is_get       | <p class="shorttext synchronized"></p>
    "! @parameter rv_processed | <p class="shorttext synchronized"></p>
    METHODS do_process_fcode_sub                                                                         " AD, 2026.10.09, changed
                                 IMPORTING is_get              TYPE /sct/au5_if_client=>ty_s_get
                                 RETURNING VALUE(rv_processed) TYPE abap_bool.

    "! <p class="shorttext synchronized">display Toast message</p>
    "!
    "! @parameter it_return  | <p class="shorttext synchronized"></p>
    "! @parameter iv_msgtype | <p class="shorttext synchronized"></p>
    METHODS do_show_message IMPORTING it_return  TYPE bapiret2_t
                                      iv_msgtype TYPE symsgty.

    METHODS get_parameter_base_ref                                                                    " AD, 2026.10.09, changed
                                   IMPORTING is_get         TYPE /sct/au5_if_client=>ty_s_get
                                             iv_full        TYPE abap_bool OPTIONAL
                                   RETURNING VALUE(rr_base) TYPE REF TO /sct/qp_s_base.

    METHODS set_parameter_guid IMPORTING iv_oguid TYPE /sct/qp_oguid OPTIONAL
                                         iv_guid  TYPE /sct/qp_guid  OPTIONAL
                               CHANGING  cs_get   TYPE /sct/au5_if_client=>ty_s_get.                                                                                                                                             " AD, 2026.10.09, changed

    "! <p class="shorttext synchronized">register sub application</p>
    METHODS do_insert_sub_app IMPORTING is_sub_app    TYPE /sct/qp_if_ui_app=>ty_s_sub_app
                              RETURNING VALUE(rr_sub) TYPE REF TO /sct/qp_if_ui_app=>ty_s_sub_app.

    "! <p class="shorttext synchronized">create a menu item</p>
    METHODS get_menu_item IMPORTING io_parent_view TYPE REF TO /sct/au5_cl_xml_view
                                    iv_text        TYPE string
                                    iv_icon        TYPE /sct/qp_icon_ui
                                    iv_action      TYPE /sct/qp_action
                                    it_arg         TYPE string_table OPTIONAL.

    "! <p class="shorttext synchronized">create a button in the footer</p>
    "!
    "! @parameter it_arg | <p class="shorttext synchronized">string table</p>
    METHODS get_footer_button IMPORTING io_parent_view TYPE REF TO /sct/au5_cl_xml_view
                                        iv_type        TYPE string
                                        iv_text        TYPE string
                                        iv_icon        TYPE string
                                        iv_action      TYPE /sct/qp_action
                                        it_arg         TYPE string_table.

    "! <p class="shorttext synchronized">create a button</p>
    "!
    "! @parameter it_arg | <p class="shorttext synchronized">string table</p>
    METHODS get_button IMPORTING io_parent_view TYPE REF TO /sct/au5_cl_xml_view
                                 iv_type        TYPE string
                                 iv_text        TYPE string
                                 iv_icon        TYPE string
                                 iv_action      TYPE /sct/qp_action
                                 it_arg         TYPE string_table.

    "! <p class="shorttext synchronized">create a menu item</p>
    METHODS get_menu IMPORTING io_parent_view TYPE REF TO /sct/au5_cl_xml_view
                               iv_type        TYPE string OPTIONAL
                               iv_icon        TYPE string OPTIONAL
                               iv_text        TYPE string
                               iv_items       TYPE string OPTIONAL
                               iv_width       TYPE string OPTIONAL
                     RETURNING VALUE(ro_view) TYPE REF TO /sct/au5_cl_xml_view.

*                            iv_name       TYPE string       OPTIONAL
    "! <p class="shorttext synchronized">Bind content to UI</p>
    METHODS _bind IMPORTING iv_fieldname  TYPE string       OPTIONAL
                            ir_data       TYPE REF TO data  OPTIONAL
                            iv_path       TYPE abap_boolean OPTIONAL
                            it_tab        TYPE data         OPTIONAL
                            iv_tab_index  TYPE i            OPTIONAL
                  RETURNING VALUE(result) TYPE string.

    "! <p class="shorttext synchronized">define Event (FCODE)</p>
    "!
    "! @parameter it_arg | <p class="shorttext synchronized">string table</p>
    METHODS _event IMPORTING iv_name       TYPE clike
                             it_arg        TYPE string_table OPTIONAL
                   RETURNING VALUE(result) TYPE string.

    "! <p class="shorttext synchronized">Complete node name : varttext/vtyppext + VNAME</p>
    "!
    "! @parameter ir_base | <p class="shorttext synchronized">base specification data</p>
    METHODS get_node_objtext IMPORTING ir_base       TYPE REF TO /sct/qp_s_base
                             RETURNING VALUE(result) TYPE string.

    METHODS get_node_vtext IMPORTING ir_base       TYPE REF TO /sct/qp_s_base
                           RETURNING VALUE(result) TYPE string.

    "! <p class="shorttext synchronized">Specification number as string</p>
    "!
    "! @parameter ir_base | <p class="shorttext synchronized">base specification data</p>
    METHODS get_node_vnr IMPORTING ir_base       TYPE REF TO /sct/qp_s_base
                         RETURNING VALUE(result) TYPE string.

    METHODS get_status_icon IMPORTING iv_istat      TYPE /sct/qp_istat         OPTIONAL
                                      ir_base       TYPE REF TO /sct/qp_s_base OPTIONAL
                            RETURNING VALUE(result) TYPE string.

    METHODS get_status_state IMPORTING iv_istat      TYPE /sct/qp_istat         OPTIONAL
                                       ir_base       TYPE REF TO /sct/qp_s_base OPTIONAL
                             RETURNING VALUE(result) TYPE string.

    METHODS get_status_type IMPORTING iv_istat      TYPE /sct/qp_istat         OPTIONAL
                                      ir_base       TYPE REF TO /sct/qp_s_base OPTIONAL
                            RETURNING VALUE(result) TYPE string.

    METHODS get_status_text IMPORTING iv_istat      TYPE /sct/qp_istat         OPTIONAL
                                      ir_base       TYPE REF TO /sct/qp_s_base OPTIONAL
                            RETURNING VALUE(result) TYPE string.

    METHODS get_ui_icon IMPORTING ir_base       TYPE REF TO /sct/qp_s_base
                        RETURNING VALUE(result) TYPE string.

    METHODS get_vart_vtyp_text IMPORTING ir_base       TYPE REF TO /sct/qp_s_base
                               RETURNING VALUE(result) TYPE string.

    METHODS init_instances.

  PRIVATE SECTION.

ENDCLASS.



CLASS /SCT/QP_CL_UI_APP IMPLEMENTATION.


  METHOD get_menu.
    " --------------------------------------------------------------------*
    " Änderungslog
    " --------------------------------------------------------------------*
    " AD, 2025.07.09, NOTE-3592, angelegt
    " --------------------------------------------------------------------*
    " FT20251105 Binding für items hinzugefügt
    " FT20260105 und width

    " An hier das MENÜ
    ro_view = io_parent_view->_generic( name   = 'MenuButton'
                                        t_prop = VALUE #( ( n = 'text'
                                                            v = iv_text )
                                                          ( n = 'type'
                                                            v = iv_type )
                                                          ( n = 'activeIcon'
                                                            v = iv_icon )
                                                          ( n = 'icon'
                                                            v = iv_icon )
                                                          ( n = 'width'
                                                            v = iv_width )
                                                          ( n = 'buttonMode'
                                                            v = 'Split' )
                                                          ( n = 'useDefaultActionOnly'
                                                            v = 'true' )  )
                         )->_generic( name = 'menu'
                         )->_generic( name   = 'Menu'
                                      t_prop = VALUE #( ( n = 'itemSelected'
                                                          v = 'onMenuAction' )
                                                        ( n = 'items'          " FT20251105
                                                          v = iv_items ) ) ).
  ENDMETHOD.


  METHOD get_button.
    " --------------------------------------------------------------------*
    " Änderungslog
    " --------------------------------------------------------------------*
    " AD, 2025.07.09, NOTE-3592, angelegt
    " --------------------------------------------------------------------*

    io_parent_view->button( type  = iv_type
                            text  = iv_text
                            icon  = iv_icon
                            id    = iv_action
                            press = ms_control-client->_event( val   = iv_action
                                                               t_arg = it_arg  ) )->get( ).
  ENDMETHOD.


  METHOD get_footer_button.
    " --------------------------------------------------------------------*
    " Änderungslog
    " --------------------------------------------------------------------*
    " AD, 2025.07.09, NOTE-3592, angelegt
    " --------------------------------------------------------------------*

    io_parent_view->_generic( name   = 'Button'
                              t_prop = VALUE #( ( n = 'type'
                                                  v = iv_type )
                                                ( n = 'text'
                                                  v = iv_text )
                                                ( n = 'icon'
                                                  v = iv_icon )
                                                ( n = 'id'
                                                  v = iv_action )
                                                ( n = 'press'
                                                  v = ms_control-client->_event( val   = iv_action
                                                                                 t_arg = it_arg ) ) ) ).
  ENDMETHOD.


  METHOD get_menu_item.
    " --------------------------------------------------------------------*
    " Änderungslog
    " --------------------------------------------------------------------*
    " AD, 2025.07.04, NOTE-3592, angelegt
    " --------------------------------------------------------------------*

    io_parent_view->menu_item( press = _event( iv_action )
                               text  = iv_text
                               icon  = iv_icon ).
*    io_parent_view->_generic( name   = 'MenuItem'
*                              t_prop = VALUE #( ( n = 'text'
*                                                  v = iv_text )
*                                                ( n = 'icon'
*                                                  v = iv_icon )
*                                                ( n = 'id'
*                                                  v = iv_action )
*                                                ( n = 'press'
*                                                  v = ms_control-client->_event( val   = iv_action
*                                                                                 t_arg = it_arg ) ) ) ).
  ENDMETHOD.


  METHOD do_insert_sub_app.
    " --------------------------------------------------------------------*
    " Änderungslog
    " --------------------------------------------------------------------*
    " AD, 2025.07.01, NOTE-3592, angelegt
    " --------------------------------------------------------------------*

    " Daten müssen geändert werden
    DATA(ls_sub_app) = is_sub_app.

    IF ls_sub_app-class IS INITIAL.
      " TODO: variable is assigned but never used (ABAP cleaner)
      SPLIT cl_abap_classdescr=>get_class_name( p_object = ls_sub_app-app ) AT '=' INTO DATA(lv_prefix) ls_sub_app-class.
    ENDIF.

    rr_sub = REF #( mt_sub_app[ id = ls_sub_app-id ] OPTIONAL ).

    IF rr_sub IS BOUND.
      rr_sub->app   = ls_sub_app-app.
      rr_sub->class = ls_sub_app-class.
    ELSE.

      " Neuer INDEX höher als der bisher benutzte?
      IF  ls_sub_app-index IS NOT INITIAL
      AND ls_sub_app-index  > mv_sub_app_index.
        mv_sub_app_index = ls_sub_app-index.
        " Wurde kein INDEX vergeben?
      ELSEIF ls_sub_app-index IS INITIAL.
        " INDEX neu vergeben, da Schlüssel
        mv_sub_app_index += 1.
        ls_sub_app-index = mv_sub_app_index.
      ENDIF.

      IF NOT (    ls_sub_app-id = mcu->id-root
               OR ls_sub_app-id = mcu->id-selection
               OR ls_sub_app-id = mcu->id-objl_root
               OR ls_sub_app-id = mcu->id-objl_child
               OR ls_sub_app-id = mcu->id-detail
               OR ls_sub_app-id = mcu->id-node ).
        ms_control-root_app->ms_appdata-sub-aidx += 1.
        ASSERT  ms_control-root_app->ms_appdata-sub-aidx <= /sct/qp_if_ui_root_app=>c_max_aidx.
        ls_sub_app-aidx = ms_control-root_app->ms_appdata-sub-aidx.
      ENDIF.

      " Neue Daten einfügen
      INSERT ls_sub_app INTO TABLE mt_sub_app REFERENCE INTO rr_sub.

    ENDIF.

*    " Daten zuerst zurücksetze, ID ist auch eindeutig
*    DELETE /sct/qp_if_ui_app~mt_sub_app WHERE id    = ls_sub_app-id
*                                           OR index = ls_sub_app-index.
  ENDMETHOD.


  METHOD set_parameter_guid.
    " --------------------------------------------------------------------*
    " Änderungslog
    " --------------------------------------------------------------------*
    " AD, 2025.07.01, NOTE-3592, angelegt
    " --------------------------------------------------------------------*

    " Alles zurücksetzen
    CLEAR cs_get-t_event_arg.

    " OGUID setzen
    IF iv_oguid IS NOT INITIAL.
      INSERT CONV #( iv_oguid ) INTO TABLE cs_get-t_event_arg.
    ENDIF.

    " GUID setzen
    IF iv_guid IS NOT INITIAL.
      INSERT CONV #( iv_guid ) INTO TABLE cs_get-t_event_arg.
    ENDIF.
  ENDMETHOD.


  METHOD get_parameter_base_ref.
    " --------------------------------------------------------------------*
    " Änderungslog
    " --------------------------------------------------------------------*
    " AD, 2025.07.01, NOTE-3592, angelegt
    " --------------------------------------------------------------------*

    TRY.
        rr_base = mo_ui_handler->get_base( iv_guid     = CONV #( is_get-t_event_arg[ 2 ] )
                                           iv_oguid    = CONV #( is_get-t_event_arg[ 1 ] )
                                           iv_stateful = is_stateful( ) ).

      CATCH cx_sy_itab_line_not_found.
        RETURN.
    ENDTRY.
  ENDMETHOD.


  METHOD do_show_message.
    " --------------------------------------------------------------------*
    " Änderungslog
    " --------------------------------------------------------------------*
    " AD, 2025.07.01, NOTE-3592, angelegt
    " --------------------------------------------------------------------*

    TRY.
        ms_control-client->message_toast_display( |{ it_return[ type = iv_msgtype ]-message }| ).
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_app~display.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_app~process_fcode.
*    constructor( ).
    IF io_client IS BOUND.
      ms_control-client ?= io_client. " AD, 2026.10.09, changed
    ENDIF.
*    IF is_get-event IS INITIAL.  "wichtig für die Neuinitializierung der Instanzen in Stateless-Mode
*      RETURN.
*    ENDIF.
*    init_instances( ). " Stateless mode
*    /sct/qp_if_ui_app~actualize_bindings( ).
    rv_processed = process_fcode_self( is_get ).

    IF rv_processed = abap_false.
      rv_processed = do_process_fcode_sub( is_get ).
    ENDIF.
  ENDMETHOD.


  METHOD constructor.
    " --------------------------------------------------------------------*
    " Änderungslog
    " --------------------------------------------------------------------*
    " AD, 2025.06.25, NOTE-3592, angelegt
    " --------------------------------------------------------------------*

    super->constructor( ).
    init_instances( ).
  ENDMETHOD.


  METHOD process_fcode_self.
    " Soll redefiniert werden

    rv_processed = abap_true.
    CASE is_get-event.
      WHEN '/SCT/QP_MY_EVENT'.

      WHEN OTHERS.
        rv_processed = abap_false.
    ENDCASE.
  ENDMETHOD.


  METHOD do_process_fcode_sub.
    LOOP AT /sct/qp_if_ui_app~mt_sub_app ASSIGNING FIELD-SYMBOL(<sub>).
      IF <sub>-app IS BOUND.
        IF <sub>-app->ms_control-root_app <> ms_control-root_app.
          <sub>-app->ms_control-root_app = ms_control-root_app. " FT20251203 ROOT-App aktualisiern (callback aus andere App )
        ENDIF.
        rv_processed = <sub>-app->process_fcode( is_get    = is_get
                                                 io_client = ms_control-client ).
        IF rv_processed = abap_true.
          EXIT.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_app~init.
    /sct/qp_if_ui_app~ms_control = is_control.
  ENDMETHOD.


  METHOD get_node_objtext.
    IF ir_base IS INITIAL OR ir_base->instance IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lv_descr) = get_vart_vtyp_text( ir_base ).

    IF ir_base->instance->ms_node_data-vname IS NOT INITIAL.
      DATA(lv_name) = ir_base->instance->ms_node_data-vname.
    ELSE.
      lv_name = get_node_vnr( ir_base ).
    ENDIF.

    result = |{ lv_descr }: { lv_name }|.
  ENDMETHOD.


  METHOD get_node_vnr.
    IF ir_base IS INITIAL OR ir_base->instance IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lv_value) = CONV /sct/qp_value( ir_base->instance->ms_node_data-vnr ).
    SHIFT lv_value LEFT DELETING LEADING '0'.
    IF lv_value IS INITIAL.
      result = |-|. " emptyindicatormode simulieren
      RETURN.
    ENDIF.
    IF ir_base->version IS NOT INITIAL.
      result = |{ lv_value }-{ ir_base->instance->ms_node_data-vvs }|.
    ELSE.
      result = |{ lv_value }|.
    ENDIF.
  ENDMETHOD.


  METHOD get_status_text.
    IF ir_base IS NOT INITIAL AND ir_base->instance IS NOT INITIAL.
      DATA(lv_istat) = ir_base->instance->ms_node_data-status-istat.
    ELSEIF iv_istat IS NOT INITIAL.
      lv_istat = iv_istat.
    ELSEIF ms_control-base IS NOT INITIAL AND ms_control-base->instance IS NOT INITIAL.
      lv_istat = ms_control-base->instance->ms_node_data-status-istat.
    ENDIF.
    IF lv_istat IS INITIAL.
      RETURN.
    ENDIF.
    " Get Status name
    mo_cust->get_tj02( EXPORTING iv_istat = lv_istat
                       IMPORTING es_tj02  = DATA(ls_tj02) ).

    result = ls_tj02-txt30.
  ENDMETHOD.


  METHOD get_vart_vtyp_text.
    IF ir_base IS INITIAL OR ir_base->instance IS INITIAL.
      RETURN.
    ENDIF.
    IF ir_base->instance->ms_node_data-vart IS NOT INITIAL.
      mo_cust->get_tvart( EXPORTING iv_vart  = ir_base->instance->ms_node_data-vart
                          IMPORTING es_tvart = DATA(ls_tvart) ).
      result = ls_tvart-varttext.
    ELSEIF ir_base->instance->ms_node_data-vtyp IS NOT INITIAL.
      mo_cust->get_tvtyp( EXPORTING iv_vtyp  = ir_base->instance->ms_node_data-vtyp
                          IMPORTING es_tvtyp = DATA(ls_tvtyp) ).
      result = ls_tvtyp-vtyptext.
    ELSEIF ir_base->vblock IS NOT INITIAL.
      mo_cust->get_tvblock( EXPORTING iv_vblock  = ir_base->vblock
                            IMPORTING es_tvblock = DATA(ls_tvblock) ).
      result = ls_tvblock-vblocktext.
    ENDIF.
  ENDMETHOD.


  METHOD get_status_icon.
    IF ir_base IS NOT INITIAL AND ir_base->instance IS NOT INITIAL.
      DATA(lv_istat) = ir_base->instance->ms_node_data-status-istat.
    ELSEIF iv_istat IS NOT INITIAL.
      lv_istat = iv_istat.
    ELSEIF ms_control-base IS NOT INITIAL AND ms_control-base->instance IS NOT INITIAL.
      lv_istat = ms_control-base->instance->ms_node_data-status-istat.
    ENDIF.
    IF lv_istat IS INITIAL.
      RETURN.
    ENDIF.
    " Get Status name
    mo_cust->get_tj02( EXPORTING iv_istat = lv_istat
                       IMPORTING es_tj02  = DATA(ls_tj02) ).

    result = ls_tj02-icon_ui.
  ENDMETHOD.


  METHOD get_status_state.
    IF ir_base IS NOT INITIAL AND ir_base->instance IS NOT INITIAL.
      DATA(lv_istat) = ir_base->instance->ms_node_data-status-istat.
    ELSEIF iv_istat IS NOT INITIAL.
      lv_istat = iv_istat.
    ELSEIF ms_control-base IS NOT INITIAL AND ms_control-base->instance IS NOT INITIAL.
      lv_istat = ms_control-base->instance->ms_node_data-status-istat.
    ENDIF.
    IF lv_istat IS INITIAL.
      result = mcu->sap-ui-core-message-MessageType-none. "  'None'. " Keine Farbe
      RETURN.
    ENDIF.

    CASE lv_istat.
      WHEN 'IZQOK'
        OR 'IZQFR'.
        result = mcu->sap-ui-core-message-MessageType-success. " 'Success'. " Grün
      WHEN 'IZQWA'.
        result = mcu->sap-ui-core-message-MessageType-warning. "'Warning'. " Orange
      WHEN 'IZQXX'
        OR 'IZQCN'
        OR 'IZQTD'.
        result = mcu->sap-ui-core-message-MessageType-error. "'Error'. " Rot
      WHEN 'IZQSP'
        OR 'IZQLO'
        OR 'IZQAL'
        OR 'IZQDN'.
        result = mcu->sap-ui-core-message-MessageType-information. "'Information'. " Blau
      WHEN OTHERS.
        result = mcu->sap-ui-core-message-MessageType-none. "'None'. " Keine Farbe
    ENDCASE.
  ENDMETHOD.


  METHOD get_status_type.
    result = get_status_state( iv_istat = iv_istat
                               ir_base  = ir_base ). " Base specification data

    " Fur die anderen Ausprägungen ( Success, Warning ) sind die Konstantengruppen Messagetype und Buttontype identisch.
    IF result = mcu->sap-ui-core-message-MessageType-error. "'Error'.
      result = mcu->sap-m-buttontype-negative. "'Negative'.
    ENDIF.

    IF result = mcu->sap-ui-core-message-MessageType-none. "'None'.
      result = mcu->sap-m-buttontype-default. "'Default'.
    ENDIF.

    IF result = mcu->sap-ui-core-message-MessageType-information.
      result = mcu->sap-m-buttontype-neutral.
    ENDIF.
  ENDMETHOD.


  METHOD _bind.
    " Fieldname ist der Name des globalen Feldes in der App, dessen Inhalt an der Oberfläche gebunden werden soll
    " Damit diese Daten von Aussen abrufbar werden  ( i.e aus der Hauptklasse /sct/qp_cl_ui ),
    " ohne die genaue Typisierung der Unterklasse kennen zu müssen,
    " Werden Referenzen zu diesen Daten in der Hauptklasse gehalten
    " Dieses anonymen Referenzen r_01...r_06 zeigen jetzt auf die globalen Daten der Unterklasse

    IF it_tab IS INITIAL.
      IF iv_fieldname IS INITIAL.
        RETURN.
      ENDIF.

      DATA(lr_ref) = REF #( me->(iv_fieldname) ).
    ELSEIF ir_data IS BOUND.
      lr_ref = ir_data.
      result = ms_control-client->_bind( val       = lr_ref->*
                                         path      = iv_path
                                         tab       = it_tab
                                         tab_index = iv_tab_index ).
    ELSE.
      BREAK-POINT.
    ENDIF.

    IF iv_fieldname IS INITIAL.
      RETURN.
    ENDIF.

*    FIELD-SYMBOLS <appdata> TYPE /sct/qp_if_ui_app=>ty_appdata.
    FIELD-SYMBOLS <appdata> TYPE any.

    IF mcu IS NOT BOUND.
      BREAK-POINT.
    ENDIF.

    IF ms_control-id = mcu->id-root
    OR ms_control-id = mcu->id-selection
    OR ms_control-id = mcu->id-objl_root
    OR ms_control-id = mcu->id-objl_child
    OR ms_control-id = mcu->id-detail
    OR ms_control-id = mcu->id-node.
      " Zugriff mit fester ID
      ASSIGN COMPONENT |{ ms_control-id }| OF STRUCTURE ms_control-root_app->ms_appdata TO <appdata>.
      DATA(lv_pathstring) = |MS_APPDATA-{ ms_control-id }-|.
    ELSE.
      " Zugriff mit ldf. Nummer für Detail-apps.
      ASSIGN COMPONENT |A_{ ms_control-aidx }| OF STRUCTURE ms_control-root_app->ms_appdata-sub TO <appdata>.
      lv_pathstring = |MS_APPDATA-SUB-A_{ ms_control-aidx }-|.

    ENDIF.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    " Lesbare ID für appdata.
    ASSIGN COMPONENT 'ID' OF STRUCTURE <appdata> TO FIELD-SYMBOL(<id>).
    IF sy-subrc = 0.
      <id> = ms_control-id.
    ENDIF.
*    <appdata>-id = ms_control-id.
    DATA(lo_appdata_type) = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_data( <appdata> ) ).
    IF lo_appdata_type->absolute_name CS 'TY_APPDATA_'.
      DATA(lv_len) = strlen( lo_appdata_type->absolute_name ) - 2.
      DATA(lv_max_idx) = CONV i( lo_appdata_type->absolute_name+lv_len ).
    ELSE.
      BREAK-POINT.
      RETURN.
    ENDIF.

    " MT_REFS enthält in der ROOT_APP alle aufgebauten anonymen Referenzen
*    ASSIGN ms_control-root_app->mt_refs[ path      = lv_pathstring
*                                         fieldname = iv_fieldname ] TO FIELD-SYMBOL(<ref>).
    DATA(ls_ref) =  ms_control-root_app->get_ref( iv_path      = lv_pathstring
                                                  iv_fieldname = iv_fieldname ).

    IF ls_ref IS NOT INITIAL.
      " Existiert bereits
*      DATA(lv_refname) = ls-refname.
      DATA(lv_exists) = abap_true.
    ELSE.
      ASSIGN COMPONENT 'RIDX' OF STRUCTURE <appdata> TO FIELD-SYMBOL(<ridx>).
      IF sy-subrc = 0.
        <ridx> += 1.
      ENDIF.
*      <appdata>-ridx += 1.
      IF <ridx> > lv_max_idx.
        BREAK-POINT.
        RETURN.
      ENDIF.
      ASSERT <ridx> <= lv_max_idx.
      ls_ref-refname = |r_{ <ridx> }|.
      ls_ref-path = lv_pathstring.
      ls_ref-fieldname = iv_fieldname.
      ms_control-root_app->set_ref( ls_ref ).

    ENDIF.

    ASSIGN COMPONENT ls_ref-refname OF STRUCTURE <appdata> TO FIELD-SYMBOL(<any>).
    IF sy-subrc = 0.

      IF lv_exists = abap_true.
        lr_ref->* = <any>->*.
        <any> = lr_ref.

      ELSE.
        <any> = lr_ref.

        result = ms_control-client->_bind( val       = lr_ref->*
                                           path      = iv_path
                                           tab       = it_tab
                                           tab_index = iv_tab_index ).

      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD _event.
    IF it_arg IS SUPPLIED.
      result = ms_control-client->_event( val   = iv_name
                                          t_arg = it_arg ).
    ELSE.
      result = ms_control-client->_event( val   = iv_name
                                          t_arg = mt_def_arg ).
    ENDIF.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_app~must_redraw_nested.
  ENDMETHOD.


  METHOD get_ui_icon.
    IF ir_base IS INITIAL OR ir_base->instance IS INITIAL.
      RETURN.
    ENDIF.
    IF ir_base->instance->ms_node_data-vart IS NOT INITIAL.
      mo_cust->get_tvart( EXPORTING iv_vart  = ir_base->instance->ms_node_data-vart
                          IMPORTING es_tvart = DATA(ls_tvart) ).
      result = ls_tvart-icon_ui.
    ELSE.
      mo_cust->get_tvtyp( EXPORTING iv_vtyp  = ir_base->instance->ms_node_data-vtyp
                          IMPORTING es_tvtyp = DATA(ls_tvtyp) ).
      result = ls_tvtyp-icon_ui.
    ENDIF.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_app~get_location.
    " FT20260720 Möglicherweise ist diese Methode nicht mehr notwendig,
    " der Hostname soll nicht bekannt sein ( es hängt zu sehr von der Architektur ab ).
    " der Relativpfad reicht idR aus, um Content anzuzeigen

    " URL des aktuellen Server holen
    DATA(lv_host) = cl_url=>get_default_host( application = iv_path ).
    IF lv_host IS NOT INITIAL.
      result = |{ lv_host }{ iv_path }|.
    ENDIF.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_app~check_changes.
  ENDMETHOD.


  METHOD init_instances.
    " Initialiserung der benötigten Klassenistanzen.
    " im Stateless-Mode müssen viele Instanzen jedes Mal neuaufgebaut werden
    /sct/qp_cl_factory=>get_instance( CHANGING co_instance = mcu ).
    /sct/qp_cl_factory=>get_instance( CHANGING co_instance = mtx ).
    /sct/qp_cl_factory=>get_instance( CHANGING co_instance = mutx ).
    /sct/qp_cl_factory=>get_instance( CHANGING co_instance = mo_ui_handler ).
  ENDMETHOD.


  METHOD /sct/qp_if_ui_app~is_stateful.
    result = ms_control-root_app->check_sticky.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_app~set_stateful.
    DATA(lv_save) = ms_control-root_app->check_sticky.
    success = ms_control-root_app->/sct/qp_if_ui_app~set_stateful( iv_stateful ).
    IF success = abap_true.
      ms_control-root_app->check_sticky = iv_stateful.
    ENDIF.


* FT20261112 unused ?
*    IF ms_control-root_app->check_sticky = abap_false AND ms_control-root_app->check_sticky <> lv_save.
*      ms_control-root_app->delete_sub_refs( ).
*    ENDIF.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_app~actualize_bindings.
    mv_bound = abap_true.
  ENDMETHOD.


  METHOD get_node_vtext.
    IF ir_base IS INITIAL OR ir_base->instance IS INITIAL.
      RETURN.
    ENDIF.

    result = VALUE #( ir_base->instance->ms_node_data-nodet[ spras = sy-langu ]-vtext OPTIONAL ).
  ENDMETHOD.
ENDCLASS.
