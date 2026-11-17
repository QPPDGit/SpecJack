CLASS /sct/qp_cl_ui_root_app DEFINITION
  PUBLIC
  INHERITING FROM /sct/qp_cl_ui_app ABSTRACT
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_serializable_object.
    INTERFACES /sct/qp_if_ui_root_app. "/sct/au5_if_app. "AD, 2026.10.09, changed

    ALIASES check_initialized FOR /sct/qp_if_ui_root_app~check_initialized. " AD, 2026.10.09, changed
    ALIASES check_sticky      FOR /sct/qp_if_ui_root_app~check_sticky.      " AD, 2026.10.09, changed
    ALIASES mv_unsaved_state  FOR /sct/qp_if_ui_root_app~mv_unsaved_state.
    ALIASES ms_appdata        FOR /sct/qp_if_ui_root_app~ms_appdata.
    ALIASES snap_selection    FOR /sct/qp_if_ui_root_app~snap_selection.

protected section.

  aliases DISPLAY
    for /SCT/QP_IF_UI_APP~DISPLAY .
  aliases INIT
    for /SCT/QP_IF_UI_APP~INIT .
  aliases MUST_REDRAW_NESTED
    for /SCT/QP_IF_UI_APP~MUST_REDRAW_NESTED .
  aliases PROCESS_FCODE
    for /SCT/QP_IF_UI_APP~PROCESS_FCODE .

  data MT_REFS type /SCT/QP_IF_UI_ROOT_APP=>TTY_REF .

  methods GET_THEME
    returning
      value(RESULT) type STRING .
  PRIVATE SECTION.
ENDCLASS.



CLASS /SCT/QP_CL_UI_ROOT_APP IMPLEMENTATION.


  METHOD /sct/au5_if_app~main.
  ENDMETHOD.


  METHOD get_theme.
    DATA(ls_get) = ms_control-client->get( ).

    IF ls_get-check_launchpad_active = abap_true.

      NEW /ui2/cl_theme_utils( )->get_theme_data(
*  exporting
*                                                            io_server        = io_server
                                                  IMPORTING es_theme_default = DATA(ls_theme_default) " Default theme id based on customizing
                                                            es_theme_pers    = DATA(ls_theme_pers) ). " Personalized theme id

      IF ls_theme_pers-id IS NOT INITIAL.
        result = ls_theme_pers-id.
      ELSE.
        result = ls_theme_default-id.
      ENDIF.

    ELSE.
      SPLIT ls_get-s_config-search AT 'sap-ui-theme=' INTO DATA(lv_before) DATA(lv_after).
      IF lv_after IS NOT INITIAL.
        " TODO: variable is assigned but never used (ABAP cleaner)
        SPLIT lv_after AT '&' INTO result DATA(lv_rest).

      ELSE.
        result = '???'.
      ENDIF.

    ENDIF.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_root_app~callback.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_root_app~delete_sub_refs.
* Clear references from all sub-apps when another content must be shown in the detail pane.
    CLEAR ms_appdata-sub.
    DELETE mt_refs WHERE path CS 'MS_APPDATA-SUB-'.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_root_app~get_context.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_root_app~get_data.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_root_app~get_footer.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_root_app~get_ref.
    result = VALUE #( mt_refs[ path      = iv_path
                               fieldname = iv_fieldname ] OPTIONAL ).
  ENDMETHOD.


  METHOD /sct/qp_if_ui_root_app~get_settings.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_root_app~popover_close.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_root_app~popover_open.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_root_app~set_data.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_root_app~set_next_event.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_root_app~set_ref.
    INSERT is_ref INTO TABLE mt_refs.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_root_app~set_stringify.
  ENDMETHOD.


  METHOD /sct/qp_if_ui_root_app~snap_selection.
  ENDMETHOD.
ENDCLASS.
