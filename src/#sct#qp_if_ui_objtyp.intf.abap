INTERFACE /sct/qp_if_ui_objtyp
  PUBLIC.

  INTERFACES /sct/qp_if_ui_app.

  TYPES:
    BEGIN OF ty_s_objtyp,
      objekttyp   TYPE /sct/qp_objekttyp,
      object      TYPE REF TO /sct/qp_if_objtyp,
      obj         TYPE REF TO /sct/qp_if_ui_app,
      base        TYPE REF TO /sct/qp_s_base,
      must_redraw TYPE abap_bool,
    END OF ty_s_objtyp.

  "! <p class="shorttext synchronized">process unconfirmed frontend changes</p>
  "!
  METHODS check_changes RETURNING VALUE(result) TYPE abap_bool.
ENDINTERFACE.
