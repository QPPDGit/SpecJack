*&---------------------------------------------------------------------*
*& Report /SCT/QP_QPPD_PARAM
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT /sct/qp_qppd_param.

PARAMETERS p_guid TYPE string DEFAULT 'EMPTY'.

INITIALIZATION.
  DATA go_ui_handler TYPE REF TO /sct/qp_if_ui_handler.

  /sct/qp_cl_factory=>get_instance( CHANGING co_instance = go_ui_handler  ).

  " GUI instanziieren
  /sct/qp_cl_factory=>get_instances( IMPORTING eo_const = DATA(gc)
                                               eo_gui   = DATA(go_gui)
                                               eo_tools = DATA(go_tools)
                                               eo_bus   = DATA(go_bus) ).

START-OF-SELECTION.
  " GUIDs ermitteln
  DATA(lt_guid) = go_ui_handler->get_guids_from_ui_guid_string( iv_guids = p_guid ).

  " GUI starten
  TRY.
      go_gui->do_start_cockpit( iv_workmode = gc->workmode_display
                                iv_screen   = gc->screen_sel
                                it_header   = VALUE #( FOR <ls_guid> IN lt_guid
                                                       ( guid = <ls_guid>-low ) )
                                iv_gui_typ  = gc->gui_typ_gui ).

    CATCH /sct/qp_cx_error INTO DATA(lo_error).
      DATA(lv_string) = lo_error->get_text( ).
      MESSAGE lv_string TYPE gc->msgtype_s DISPLAY LIKE gc->msgtype_e.
  ENDTRY.
