CLASS /sct/qp_cl_ui_tree_ft DEFINITION
  PUBLIC
  INHERITING FROM /sct/qp_cl_gts
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES /sct/qp_if_ui_tree_ft.

    METHODS do_build_tree_copy.
    METHODS do_build_tree_fcat_copy.

  PROTECTED SECTION.

  PRIVATE SECTION.
ENDCLASS.



CLASS /SCT/QP_CL_UI_TREE_FT IMPLEMENTATION.


  METHOD do_build_tree_copy.
  ENDMETHOD.


  METHOD do_build_tree_fcat_copy.
    " --------------------------------------------------------------------*
    " Änderungslog
    " --------------------------------------------------------------------*
    " AD, 2025.06.17, NOTE-3592, angelegt
    " --------------------------------------------------------------------*
  ENDMETHOD.
ENDCLASS.
