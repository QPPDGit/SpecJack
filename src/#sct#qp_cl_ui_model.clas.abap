CLASS /sct/qp_cl_ui_model DEFINITION
  PUBLIC
  INHERITING FROM /sct/qp_cl_qv_model
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES /sct/qp_if_ui_model.

    METHODS constructor.

  PROTECTED SECTION.

  PRIVATE SECTION.
ENDCLASS.



CLASS /SCT/QP_CL_UI_MODEL IMPLEMENTATION.


  METHOD /sct/qp_if_ui_model~get_base.
    /sct/qp_if_model~get_base( EXPORTING iv_guid     = iv_guid
                                         iv_root_key = iv_oguid
                               IMPORTING er_base     = rr_base ).
  ENDMETHOD.


  METHOD /sct/qp_if_ui_model~get_hierarchy.
    CLEAR et_base.

    IF iv_oguid IS INITIAL.
      DATA(lv_oguid) = iv_guid.
    ELSE.
      lv_oguid = iv_oguid.
    ENDIF.

    IF NOT line_exists( mt_base[ KEY guid COMPONENTS guid = lv_oguid ] ).

      mo_data->get_data( EXPORTING is_input   = VALUE #( guid           = lv_oguid
                                                         read_hierarchy = abap_true
                                                         sel_tables     = VALUE #( node    = abap_true
                                                                                   nodet   = abap_true
                                                                                   noderel = abap_true
                                                                                   status  = abap_true ) )
                         IMPORTING es_db_data = DATA(ls_data) ).

      DATA(lr_sel) = REF #( ls_data-node[ KEY guid COMPONENTS guid = iv_guid ] OPTIONAL ).
      IF iv_oguid IS INITIAL AND lr_sel IS BOUND.
        lv_oguid = lr_sel->oguid.
      ELSE.
        lv_oguid = iv_oguid.
      ENDIF.
      mo_data->get_data( EXPORTING is_input   = VALUE #( guid           = iv_guid
                                                         read_hierarchy = abap_false  )
                         IMPORTING es_db_data = DATA(ls_data_detail) ).

*     INSERT LINES OF ls_data_detail-ana INTO TABLE ls_data-ana.
      INSERT LINES OF ls_data_detail-bds INTO TABLE ls_data-bds.
      INSERT LINES OF ls_data_detail-log INTO TABLE ls_data-log.
      INSERT LINES OF ls_data_detail-pmk INTO TABLE ls_data-pmk.
      INSERT LINES OF ls_data_detail-stx INTO TABLE ls_data-stx.
      INSERT LINES OF ls_data_detail-text INTO TABLE ls_data-text.
      INSERT LINES OF ls_data_detail-val INTO TABLE ls_data-val.
      INSERT LINES OF ls_data_detail-valt INTO TABLE ls_data-valt.

      mo_data->map_data_db_to_qvc( EXPORTING is_db_data  = ls_data
                                   IMPORTING et_qvc_data = DATA(lt_qvc_data) ).

      do_load_process( EXPORTING is_data_select = VALUE #( guid = lv_oguid )
                       IMPORTING et_base_root   = DATA(lt_base_root)
                       CHANGING  ct_qvc_data    = lt_qvc_data ).
      LOOP AT lt_base_root ASSIGNING FIELD-SYMBOL(<ls_base_root>).
        set_workmode_obj( ir_base_root = <ls_base_root>
                          iv_workmode  = mc->workmode_display ).
      ENDLOOP.
      TRY.
          do_load_init( it_base_root = lt_base_root ).
        CATCH /sct/qp_cx_error.
        " Laden ging nicht gut.(QPPD-seitig) TD setzen ?
        CATCH cx_root.
          " Laden schiefgegangen (z.B. fehlendes Customizing cx_sy_itab_line_not_found in CL_CUST)
      ENDTRY.

    ENDIF.

    TRY.
        IF iv_oguid IS INITIAL.
          rr_base = REF #( mt_base[ KEY guid COMPONENTS guid = lv_oguid ] OPTIONAL ).
        ELSE.
          rr_base = REF #( mt_base[ KEY guid COMPONENTS guid = iv_guid ] OPTIONAL ).
        ENDIF.
        IF et_base IS SUPPLIED AND rr_base IS BOUND.
          et_base = /sct/qp_if_model~get_base_childs( rr_base ).
          SORT et_base BY table_line->sortkr.
          " Resolve VBLOCK :
          " Die Vblöcke werden in Stateless Mode jedes Mal neu erzeugt ( mit neuen GUIDs ) es ist als not möglich zwischen das angeklickte VBLOCK wieder zu finden

          DO.
            LOOP AT et_base ASSIGNING FIELD-SYMBOL(<base>)
                 WHERE table_line->vblock IS NOT INITIAL.
              DATA(lv_index) = sy-tabix.
              IF <base>->vblock IS NOT INITIAL.
                DATA(lt_base_sub) = /sct/qp_if_model~get_base_childs( <base> ).
                SORT lt_base_sub BY table_line->sortkr.

                DELETE et_base INDEX lv_index.
                INSERT LINES OF lt_base_sub INTO et_base INDEX lv_index.
              ENDIF.
            ENDLOOP.
            IF sy-subrc <> 0.
              EXIT.
            ENDIF.
          ENDDO.

        ENDIF.

      CATCH cx_root.
    ENDTRY.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_model~get_instance.
    " *********************************************************************
    " get singleton instance
    " *********************************************************************

    /sct/qp_cl_factory=>get_instance( CHANGING co_instance = ro_instance ).
  ENDMETHOD.


  METHOD constructor.
    super->constructor( ).
    /sct/qp_cl_factory=>get_instances( IMPORTING eo_data = mo_data ).
    ms_active-gui_typ = mc->gui_typ_gui.
    ms_active-profile = mc->profile_default.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_model~get_base_parents.
    rtref_base = /sct/qp_if_model~get_base_parents( ir_base ).
  ENDMETHOD.


  METHOD /sct/qp_if_ui_model~is_base_action_allowed.
    rv_allowed = /sct/qp_if_model~is_base_action_allowed( iv_action = iv_action                  " Aktionscode
                                                          ir_base   = ir_base ).
  ENDMETHOD.


  METHOD /sct/qp_if_ui_model~get_base_parent_resolve_vblock.
    rr_base_parent = /sct/qp_if_model~get_base_parent_resolve_vblock( ir_base ).
  ENDMETHOD.
ENDCLASS.
