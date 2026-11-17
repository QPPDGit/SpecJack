CLASS /sct/qp_cl_ui_detail DEFINITION
  PUBLIC
  INHERITING FROM /sct/qp_cl_ui_app
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_serializable_object.
    INTERFACES /sct/qp_if_ui_detail.

    ALIASES display FOR /sct/qp_if_ui_app~display.

    METHODS constructor.

    METHODS /sct/qp_if_ui_app~actualize_bindings REDEFINITION.
    METHODS /sct/qp_if_ui_app~display            REDEFINITION.
    METHODS /sct/qp_if_ui_app~init               REDEFINITION.
    METHODS /sct/qp_if_ui_app~must_redraw_nested REDEFINITION.

  PROTECTED SECTION.
    TYPES:
      BEGIN OF ty_s_node,
        base TYPE REF TO /sct/qp_s_base,
        guid TYPE /sct/qp_guid,
        obj  TYPE REF TO /sct/qp_if_ui_node,
      END OF ty_s_node.
    TYPES ty_t_node TYPE SORTED TABLE OF ty_s_node WITH UNIQUE KEY base.

    DATA mo_node TYPE REF TO /sct/qp_if_ui_node.

    METHODS process_fcode_self REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.



CLASS /SCT/QP_CL_UI_DETAIL IMPLEMENTATION.


  METHOD constructor.
    " --------------------------------------------------------------------*
    " Änderungslog
    " --------------------------------------------------------------------*
    " AD, 2025.06.18, NOTE-3592, angelegt
    " --------------------------------------------------------------------*
    super->constructor( ).
  ENDMETHOD.


  METHOD /sct/qp_if_ui_app~init.
    " --------------------------------------------------------------------*
    " Änderungslog
    " --------------------------------------------------------------------*
    " AD, 2025.06.18, NOTE-3592, angelegt
    " --------------------------------------------------------------------*

    super->/sct/qp_if_ui_app~init( is_control = is_control ).

    init_instances( ).

    " Aktuell wird alles an die Subklasse /sct/qp_ui_node weitergeleitet

*    IF mo_node IS BOUND.
*      mo_node->/sct/qp_if_ui_app~init( is_control = VALUE #( BASE is_control
*                                                             parent_app = me ) ).
*
*      RETURN.
*    ENDIF.

    IF mo_node IS NOT BOUND.
      DATA(lv_classname) = /sct/qp_cl_factory=>get_classname( iv_classname = CONV #( '/SCT/QP_CL_UI_NODE' ) ).
      IF lv_classname IS INITIAL.
        lv_classname = CONV #( '/SCT/QP_CL_UI_NODE' ).
      ENDIF.

      TRY.
          CREATE OBJECT mo_node TYPE (lv_classname).
        CATCH cx_sy_create_object_error.

      ENDTRY.
    ENDIF.
    " Die NODE Klasse registrieren
    do_insert_sub_app( is_sub_app = VALUE #( index = 1
                                             id    = mcu->id-node
                                             app   = mo_node ) ).

    mo_node->/sct/qp_if_ui_app~init( is_control = VALUE #( BASE is_control
                                                           parent_app = me
                                                           id         = mcu->id-node ) ).
  ENDMETHOD.


  METHOD process_fcode_self.
    " --------------------------------------------------------------------*
    " Änderungslog
    " --------------------------------------------------------------------*

    " Hier Keine Aktionen abarbeiten, sondern nur in den Sub-Klassen
  ENDMETHOD.


  METHOD /sct/qp_if_ui_app~display.
    ms_control-parent_view = io_view.
    ms_control-client      = io_client.

    IF mo_node IS BOUND.
      mo_node->/sct/qp_if_ui_app~display( io_view   = io_view
                                          io_client = io_client ).
    ENDIF.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_app~must_redraw_nested.
    IF mo_node IS BOUND.
      result = mo_node->/sct/qp_if_ui_app~must_redraw_nested( ).
    ELSE.
*      BREAK tromfra.
    ENDIF.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_app~actualize_bindings.
    IF mo_node IS BOUND.
      mo_node->/sct/qp_if_ui_app~actualize_bindings( ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
