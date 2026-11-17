INTERFACE /sct/qp_if_ui_tree_mt
  PUBLIC.

  INTERFACES /sct/au5_if_app.
  INTERFACES /sct/qp_if_ui_app.

  TYPES:
    BEGIN OF ty_s_tree3,
      is_selected TYPE abap_bool,
      key         TYPE /sct/qp_guid,
      oguid       TYPE /sct/qp_guid,
      guid        TYPE /sct/qp_guid,
      vname       TYPE string,
      istat       TYPE string,
      descr       TYPE string,
    END OF ty_s_tree3.
  TYPES:
    BEGIN OF ty_s_tree2,
      is_selected TYPE abap_bool,
      key         TYPE /sct/qp_guid,
      oguid       TYPE /sct/qp_guid,
      guid        TYPE /sct/qp_guid,
      vname       TYPE string,
      istat       TYPE string,
      descr       TYPE string,
      nodes       TYPE STANDARD TABLE OF ty_s_tree3 WITH DEFAULT KEY,
    END OF ty_s_tree2.
  TYPES:
    BEGIN OF ty_s_tree1,
      is_selected TYPE abap_bool,
      key         TYPE /sct/qp_guid,
      oguid       TYPE /sct/qp_guid,
      guid        TYPE /sct/qp_guid,
      vname       TYPE string,
      istat       TYPE string,
      descr       TYPE string,
      nodes       TYPE STANDARD TABLE OF ty_s_tree2 WITH DEFAULT KEY,
    END OF ty_s_tree1.
  TYPES ty_t_tree1 TYPE STANDARD TABLE OF ty_s_tree1 WITH DEFAULT KEY.

  DATA mt_tree TYPE ty_t_tree1.
ENDINTERFACE.
