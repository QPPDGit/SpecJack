"! <p class="shorttext synchronized">UI TOE Search Help</p>
CLASS /sct/qp_cl_ui_toe DEFINITION
  PUBLIC
  INHERITING FROM /sct/qp_cl_toe
  CREATE PUBLIC.

  PUBLIC SECTION.
    DATA ms_mamba_toe_line TYPE /sct/qp_s_mamba_ref.

    METHODS rebuild_context        CHANGING cs_toe TYPE /sct/qp_s_toe.

    METHODS /sct/qp_if_toe~f4_call REDEFINITION.

  PROTECTED SECTION.
    DATA mo_ui_f4 TYPE REF TO /sct/qp_if_ui_searchhelp.

  PRIVATE SECTION.
ENDCLASS.



CLASS /SCT/QP_CL_UI_TOE IMPLEMENTATION.


  METHOD /sct/qp_if_toe~f4_call.
    DATA(ls_toe) = /sct/qp_if_toe~get_toe_structure( is_toe ).
    IF NOT ( ls_toe-gruelm IS BOUND AND ls_toe-gruelm->tobel IS BOUND ).
      RETURN.
    ENDIF.
    IF ls_toe-gruelm->tobel->shlp IS INITIAL.

      RAISE EXCEPTION TYPE /sct/qp_cx_error EXPORTING textid = mx->gruelm_not_found
                                                      msgv1  = CONV #( ls_toe-element )
                                                      msgv2  = CONV #( ls_toe-objekttyp ).
      RETURN.
    ENDIF.
*    DATA ls_line TYPE /sct/qp_s_mamba_ref.
*
*    MOVE-CORRESPONDING ls_toe TO ls_line ##ENH_OK.
*
*    do_build_context( EXPORTING ir_line = REF #( ls_line )
*                      CHANGING  cs_toe  = ls_toe ).
*    IF is_toe-value IS NOT INITIAL AND is_toe-value CS '*'.
*      ls_toe-value = is_toe-value.
*    ENDIF.
*
*    " Der Suchhilfe Klasse die aktuelle Instanz mitteilen.
*    /sct/qp_cl_sx_toe=>set_toe( io_toe = me
*                                is_toe = ls_toe ).
    " Suchhilfe ausfuehren
    mo_ui_f4 = /sct/qp_cl_ui_searchhelp=>get_instance( ).
    mo_ui_f4->init( is_toe          = ls_toe
                    iv_multi_result = xsdbool( ls_toe-gruelm->multielem IS NOT INITIAL )
                    is_callback     = is_callback ).
    io_ui_client->nav_app_call( CAST /sct/au5_if_app( mo_ui_f4 ) ).

*    DATA(lt_return) = /sct/qp_cl_sx_toe=>f4_start_value_request( is_shlp     = ls_shlp         " Name der Suchhilfe Bescheibung
*                                                                 iv_disponly = iv_disponly ). " nur Anzeige keine Auswahl

*    " Rueckgabe der Werte mit uebersetzung des Suchhilfe Feldnamens ins Element
*    rt_values = VALUE #( FOR lines IN lt_return
*                         ( element = COND #( WHEN lines-fieldname = ls_toe-gruelm->tobel->shlp_fieldname
*                                             THEN ls_toe-element
*                                             ELSE lines-fieldname )
*                           value   = lines-fieldval ) ).
*    rt_values = f4_result( is_toe    = ls_toe
*                           it_values = rt_values ).
  ENDMETHOD.


  METHOD rebuild_context.
    " Kontextewerte zu einer globalen mamba_line abspeichern
    CLEAR ms_mamba_toe_line.
    MOVE-CORRESPONDING cs_toe TO ms_mamba_toe_line ##ENH_OK.

    do_build_context( EXPORTING ir_line = REF #( ms_mamba_toe_line )
                      CHANGING  cs_toe  = cs_toe ).
  ENDMETHOD.
ENDCLASS.
