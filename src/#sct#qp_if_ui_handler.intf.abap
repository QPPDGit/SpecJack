INTERFACE /sct/qp_if_ui_handler
  PUBLIC.


  TYPES:
    BEGIN OF ty_s_tree,
      key                   TYPE /sct/qp_guid,
      guid                  TYPE /sct/qp_guid,
      root_guid             TYPE /sct/qp_guid,
      root_key              TYPE /sct/qp_guid,
      parent_guid           TYPE /sct/qp_guid,
      parent_key            TYPE /sct/qp_guid,

      relattyp              TYPE /sct/qp_relattyp,
      workmode              TYPE /sct/qp_workmode,
      node_vname            TYPE /sct/qp_vname,
      node_vtext            TYPE /sct/qp_vtext,
      node_vnr              TYPE /sct/qp_vnr,
      node_vvs              TYPE /sct/qp_vvs,
      node_istat            TYPE /sct/qp_istat,
      node_istat_icon       TYPE /sct/qp_icon_ui,
      node_istat_icon_color TYPE /sct/qp_icon_ui_color,

      icon_ui               TYPE /sct/qp_icon_ui,
      icon_ui_criticality   TYPE /sct/qp_icon_ui_criticality, " AD, 2025.11.17, NOTE-3592, umbenannt
    END OF ty_s_tree.
  TYPES ty_t_tree TYPE STANDARD TABLE OF ty_s_tree WITH DEFAULT KEY.

  CLASS-DATA mv_use_stateless_model TYPE abap_bool.
  DATA mv_profile TYPE /sct/qp_profile.

  METHODS get_guids_from_ui_guid_string IMPORTING iv_guids       TYPE string
                                        RETURNING VALUE(rt_guid) TYPE /sct/qp_t_range_guid.

  METHODS get_guids_from_ui_vnr_string IMPORTING iv_string      TYPE string
                                       RETURNING VALUE(rt_guid) TYPE /sct/qp_t_range_guid.

  METHODS get_hierarchy IMPORTING iv_guid        TYPE /sct/qp_guid
                                  iv_oguid       TYPE /sct/qp_oguid
                                  iv_stateful    TYPE abap_bool
                        EXPORTING et_base        TYPE /sct/qp_tref_base
                        RETURNING VALUE(rr_base) TYPE REF TO /sct/qp_s_base.

  METHODS get_base IMPORTING iv_guid        TYPE /sct/qp_guid
                             iv_oguid       TYPE /sct/qp_oguid
                             iv_stateful    TYPE abap_bool
                   RETURNING VALUE(rr_base) TYPE REF TO /sct/qp_s_base.

  METHODS get_base_parents IMPORTING ir_base        TYPE REF TO /sct/qp_s_base
                                     iv_stateful    TYPE abap_bool
                           RETURNING VALUE(rt_base) TYPE /sct/qp_t_base.

  METHODS is_base_action_allowed IMPORTING iv_action     TYPE /sct/qp_action
                                           ir_base       TYPE REF TO /sct/qp_s_base
                                 RETURNING VALUE(result) TYPE abap_bool.

  METHODS get_base_parent_resolve_vblock IMPORTING ir_base               TYPE REF TO /sct/qp_s_base
                                                   iv_stateful           TYPE abap_bool
                                         RETURNING VALUE(rs_base_parent) TYPE /sct/qp_s_base
                                         RAISING   /sct/qp_cx_error.
ENDINTERFACE.
