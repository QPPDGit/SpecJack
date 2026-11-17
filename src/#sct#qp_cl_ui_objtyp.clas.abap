CLASS /sct/qp_cl_ui_objtyp DEFINITION
  PUBLIC
  INHERITING FROM /sct/qp_cl_ui_app ABSTRACT
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES /sct/qp_if_ui_objtyp.

    METHODS constructor                          IMPORTING is_obj TYPE /sct/qp_if_ui_objtyp=>ty_s_objtyp.

    METHODS /sct/qp_if_ui_app~check_changes      REDEFINITION.
    METHODS /sct/qp_if_ui_app~must_redraw_nested REDEFINITION.
    METHODS /sct/qp_if_ui_app~init               REDEFINITION.

  PROTECTED SECTION.
    ALIASES check_changes FOR /sct/qp_if_ui_objtyp~check_changes.

    DATA ms_node_object TYPE /sct/qp_s_node_object.
    DATA ms_obj         TYPE /sct/qp_if_ui_objtyp=>ty_s_objtyp.

    "! <p class="shorttext synchronized">is the event for this object type relevant ?</p>
    METHODS is_event_relevant IMPORTING is_get        TYPE /sct/au5_if_client=>ty_s_get
                              RETURNING VALUE(result) TYPE abap_bool.

    METHODS is_editable        RETURNING VALUE(rv_bool) TYPE abap_bool.

    METHODS init               IMPORTING client         TYPE REF TO /sct/au5_if_client.

    METHODS process_fcode_self REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.



CLASS /SCT/QP_CL_UI_OBJTYP IMPLEMENTATION.


  METHOD constructor.
    super->constructor( ).
    ms_obj = is_obj.
    IF ms_obj-object IS BOUND.
      ms_node_object = ms_obj-object->ms_node_object.
    ENDIF.
    mt_def_arg = VALUE #( ( CONV #( ms_obj-base->oguid ) )
                          ( CONV #( ms_obj-base->guid ) )
                          ( CONV #( is_obj-objekttyp ) ) ).
  ENDMETHOD.


  METHOD is_event_relevant.
    IF lines( is_get-t_event_arg ) >= 3.
      IF  CONV bel_guid( ms_control-base->oguid ) = is_get-t_event_arg[ 1 ]
      AND CONV bel_guid( ms_control-base->guid )  = is_get-t_event_arg[ 2 ]
      AND ms_node_object-objekttyp                = is_get-t_event_arg[ 3 ].
        " Kann prozessiert werden : Event gehört zum aktuellen APP bzw Objekttyp
        result = abap_true.
      ELSE.
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD process_fcode_self.
    ms_obj-must_redraw = abap_false.
    rv_processed = super->process_fcode_self( is_get ).
    IF rv_processed = abap_true.
    ENDIF.
  ENDMETHOD.


  METHOD is_editable.
    " --------------------------------------------------------------------*
    " Editierbarkeit aus dem Knoten bzw. aus der Base.
    " --------------------------------------------------------------------*
    IF ms_obj-object->ms_control-workmode = mc->workmode_change AND ms_obj-object->ms_control-noedit IS INITIAL.
      rv_bool = abap_true.
    ELSE.
      rv_bool = abap_false.
    ENDIF.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_app~check_changes.
    result = /sct/qp_if_ui_objtyp~check_changes( ).
  ENDMETHOD.


  METHOD /sct/qp_if_ui_app~must_redraw_nested.
* Setzt ein Objekttyp das Flag ms_obj-must_redraw, dann ist ein komplpettes Redraw der nested Page notwendig.
* Im normalfall ( must_redraw = space ) wird lediglich ein model_update gemacht,
    result = ms_obj-must_redraw.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_objtyp~check_changes.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_app~init.
    super->/sct/qp_if_ui_app~init( is_control ).
    ms_control-id = |{ ms_control-base->guid }_{ ms_node_object-objekttyp }|.
  ENDMETHOD.


  METHOD init.
  ENDMETHOD.
ENDCLASS.
