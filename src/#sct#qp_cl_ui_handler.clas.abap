CLASS /sct/qp_cl_ui_handler DEFINITION
  PUBLIC
  INHERITING FROM /sct/qp_cl_gts
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES /sct/qp_if_ui_handler.

    METHODS constructor.

  PROTECTED SECTION.
    ALIASES mv_use_stateless_model FOR /sct/qp_if_ui_handler~mv_use_stateless_model.

    " data C_PIC_URL type STRING value 'https://sapui5.hana.ondemand.com/sdk/test-resources/sap/ui/documentation/sdk/images/' ##NO_TEXT.
    " data MV_SESSION_IS_STATEFUL type ABAP_BOOL .

    CLASS-DATA mo_ui_model TYPE REF TO /sct/qp_if_ui_model.
ENDCLASS.



CLASS /SCT/QP_CL_UI_HANDLER IMPLEMENTATION.


  METHOD constructor.
    " --------------------------------------------------------------------*
    " Änderungslog
    " --------------------------------------------------------------------*
    " AD, 2025.04.16, NOTE-3592, angelegt
    " --------------------------------------------------------------------*

    super->constructor( ).
    /sct/qp_cl_factory=>get_instances( IMPORTING eo_bus        = mo_bus
                                                 eo_controller = mo_controller
                                                 eo_error      = mx ).

    /sct/qp_cl_factory=>get_instance( CHANGING co_instance = mo_ui_model ).

    /sct/qp_if_ui_handler~mv_use_stateless_model = abap_true.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_handler~get_guids_from_ui_guid_string.
    " --------------------------------------------------------------------*
    " Änderungslog
    " --------------------------------------------------------------------*
    " AD, 2025.05.20, NOTE-3592, angelegt
    " --------------------------------------------------------------------*

    DATA(lv_guids) = iv_guids.
    TRANSLATE lv_guids USING '- '.
    TRANSLATE lv_guids TO UPPER CASE.
    CONDENSE lv_guids NO-GAPS.

    SPLIT lv_guids AT ',' INTO TABLE DATA(lt_guids_split).

    IF lt_guids_split IS NOT INITIAL.

      rt_guid = VALUE #(  FOR <ls_guids_split> IN lt_guids_split
                         ( sign   = mc->sign_i
                           option = mc->option_eq
                           low    = CONV #( <ls_guids_split> ) ) ).

    ENDIF.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_handler~get_hierarchy.
    " *********************************************************************
    " Einlesen von Vorschrifenenarten mit Hierarchie
    " Die Methode entscheidet ob stateful oder stateless eingelesen wird
    " *********************************************************************

    CLEAR et_base.
    IF iv_oguid IS NOT INITIAL.
      rr_base = mo_controller->get_base( iv_guid     = iv_guid
                                         iv_root_key = iv_oguid ).
    ELSE.
      rr_base = mo_controller->get_base( iv_guid = iv_guid ).
    ENDIF.

    IF rr_base IS NOT INITIAL.
      " Das Objekt ist ins standard Model geladen worden, es wird damit weitergearbeitet
      IF et_base IS SUPPLIED.
        mo_controller->get_mod_base_childs( EXPORTING is_base     = rr_base->*
                                            IMPORTING et_base_ref = et_base ).
      ENDIF.

    ELSE.
      " Nicht im Standard Model geladen, dann ins UI Model (stateless) laden

      IF mv_use_stateless_model = abap_true AND iv_stateful = abap_false.

        mo_controller->set_active( iv_profile  = /sct/qp_if_ui_handler~mv_profile
                                   iv_gui_typ  = mc->gui_typ_gui
                                   iv_workmode = mc->workmode_display ).

        " Stateless laden von Instanzen
        rr_base = mo_ui_model->get_hierarchy( EXPORTING iv_guid  = iv_guid
                                                        iv_oguid = iv_oguid
                                              IMPORTING et_base  = et_base ).

      ELSE.
        " Vor dem einlesen von Daten Profil setzen, damit die erlaublten Aktionen richtig ermittelt werden können
        mo_controller->set_active( iv_profile  = /sct/qp_if_ui_handler~mv_profile
                                   iv_gui_typ  = mc->gui_typ_gui
                                   iv_workmode = mc->workmode_change ).

        IF iv_oguid IS NOT INITIAL.
          mo_controller->get_mod_node_root( is_node_keys = VALUE #( guid  = iv_oguid
                                                                    oguid = iv_oguid ) ).

          rr_base = mo_controller->get_base( iv_guid     = iv_guid
                                             iv_root_key = iv_oguid ).
        ELSE.

          mo_controller->get_mod_node_root( EXPORTING is_node_keys = VALUE #( guid = iv_guid )
                                            IMPORTING es_base      = DATA(ls_base) ).

          rr_base = mo_controller->get_base( iv_guid     = iv_guid
                                             iv_root_key = ls_base-oguid ).

        ENDIF.

        IF rr_base IS NOT INITIAL.
          " Das Objekt ist ins standard Model geladen worden, es wird damit weitergearbeitet
          IF et_base IS SUPPLIED.
            mo_controller->get_mod_base_childs( EXPORTING is_base     = rr_base->*
                                                IMPORTING et_base_ref = et_base ).
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_handler~get_base.
    " *********************************************************************
    " Liefert ein Base Eintrag zu guid/oguid.
    " Die Methode entscheidet ob stateful oder stateless eingelesen wird
    " *********************************************************************

    " In stateful model geladen ?
    rr_base = mo_controller->get_base( iv_guid     = iv_guid
                                       iv_root_key = iv_oguid ).

    IF rr_base IS NOT INITIAL.
      RETURN.
    ENDIF.

    IF mv_use_stateless_model = abap_true AND iv_stateful = abap_false.

      mo_controller->set_active( iv_profile  = /sct/qp_if_ui_handler~mv_profile
                                 iv_gui_typ  = mc->gui_typ_gui
                                 iv_workmode = mc->workmode_display ).

      " In stateless model geladen ?
      rr_base = mo_ui_model->get_base( iv_guid  = iv_guid
                                       iv_oguid = iv_oguid ).
      IF rr_base IS INITIAL.
        " in CL_UI_MODEL nachladen
        rr_base = mo_ui_model->get_hierarchy( iv_oguid = iv_oguid   " Original GUID; Assigned to header specification
                                              iv_guid  = iv_guid ). " Specification GUID

      ENDIF.

    ELSE.
      " in CL_QV_MODEL nachladen
      " Vor dem einlesen von Daten Profil setzen, damit die erlaublten Aktionen richtig ermittelt werden können
      mo_controller->set_active( iv_profile  = /sct/qp_if_ui_handler~mv_profile
                                 iv_gui_typ  = mc->gui_typ_gui
                                 iv_workmode = mc->workmode_change ).

      mo_controller->get_mod_node_root( is_node_keys = VALUE #( guid  = iv_guid
                                                                oguid = iv_oguid ) ).
      rr_base = mo_controller->get_base( iv_guid     = iv_guid
                                         iv_root_key = iv_oguid ).

    ENDIF.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_handler~get_base_parents.
    " *********************************************************************
    " Liefert alle Elternknoten eines Base Eintrages
    " Die Methode entscheidet ob stateful oder stateless eingelesen wird
    " *********************************************************************

    " In stateful model geladen ?
    rt_base = mo_controller->get_base_parents( iv_key = ir_base->key ).

    IF rt_base IS NOT INITIAL.
      RETURN.
    ENDIF.

    IF mv_use_stateless_model = abap_true AND iv_stateful = abap_false.
      " In stateless model geladen ?
      DATA(ltr_base) = mo_ui_model->get_base_parents( ir_base = ir_base ).
      LOOP AT ltr_base INTO DATA(lr_base).
        " Die Reihenfolge ist wichtig
        " VART zuerst dann die unteren Knoten inkl Gruppen bis ausgeschlossen (iv_guid, iv_key)
        IF lr_base->vblock IS INITIAL.
          INSERT lr_base->* INTO rt_base INDEX 1.
        ENDIF.
      ENDLOOP.
* An dieser Stelle kein Nachladen notwendig
*        IF rr_base IS INITIAL.
*          "in CL_UI_MODEL nachladen
*          rr_base = mo_ui_model->get_hierarchy( iv_oguid = iv_oguid   " Original GUID; Assigned to header specification
*                                                iv_guid  = iv_guid ). " Specification GUID
*
*        ENDIF.

    ELSE.
      " in CL_QV_MODEL nachladen
*        mo_controller->get_mod_node_root(
*          EXPORTING
*            is_node_keys = VALUE #( guid = ir_base->guid oguid = ir_base->oguid ) ).
*        lt_base = mo_controller->get_mod_base_parents( iv_key = ir_base->key ).
    ENDIF.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_handler~is_base_action_allowed.
    DATA(lr_base) = mo_controller->get_base( iv_guid     = ir_base->guid
                                             iv_root_key = ir_base->oguid ).

    IF lr_base IS BOUND.
      result = mo_controller->is_mod_base_action_allowed( iv_action = iv_action                 " Aktionscode
                                                          is_base   = lr_base->* ). " Daten Vorschriften Hierarchie

    ELSE.
      IF mv_use_stateless_model = abap_true.
        result = mo_ui_model->is_base_action_allowed( iv_action = iv_action                 " Aktionscode
                                                      ir_base   = ir_base ). " Daten Vorschriften Hierarchie

      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_handler~get_guids_from_ui_vnr_string.
    SPLIT iv_string AT ',' INTO TABLE DATA(lt_vnrvvs).

    DATA lt_node TYPE TABLE OF /sct/qp_node.

    DATA lv_vnr  TYPE /sct/qp_vnr.
    DATA lv_vvs  TYPE /sct/qp_vvs.

    LOOP AT lt_vnrvvs ASSIGNING FIELD-SYMBOL(<lv_vnrvvs>).

      SPLIT <lv_vnrvvs> AT '-' INTO DATA(lv_vnr_str) DATA(lv_vvs_str).

      IF lv_vnr_str IS INITIAL.
        CONTINUE.
      ENDIF.
      lv_vnr = lv_vnr_str.
      IF lv_vnr_str IS INITIAL.
        CONTINUE.
      ENDIF.
      IF lv_vvs_str IS NOT INITIAL.
        lv_vvs = lv_vvs_str.
      ELSE.
        lv_vvs = '001'.
      ENDIF.

      INSERT VALUE #( vnr = lv_vnr
                      vvs = lv_vvs ) INTO TABLE lt_node.

    ENDLOOP.

    IF lt_node IS NOT INITIAL.
      SELECT guid AS low FROM /sct/qp_node
        FOR ALL ENTRIES IN @lt_node
        WHERE vnr = @lt_node-vnr AND vvs = @lt_node-vvs
        INTO CORRESPONDING FIELDS OF TABLE @rt_guid.

    ENDIF.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_handler~get_base_parent_resolve_vblock.
    " *********************************************************************
    " Liefert der erste Elternknoten, der kein VBLOCK ist
    " Die Methode entscheidet ob stateful oder stateless eingelesen wird
    " *********************************************************************

    " In stateful model geladen ?
    TRY.
        rs_base_parent = mo_controller->/sct/qp_if_controller~get_base_parent_resolve_vblock( is_base = ir_base->* ).
      CATCH /sct/qp_cx_error.
        " NODE INFO NOT SUFFICIENT wird geschmissen
    ENDTRY.

    IF rs_base_parent IS NOT INITIAL.
      RETURN.
    ENDIF.

    IF mv_use_stateless_model = abap_true AND iv_stateful = abap_false.
      " In stateless model geladen ?
      rs_base_parent = mo_ui_model->get_base_parent_resolve_vblock( ir_base )->*.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
