INTERFACE /sct/qp_if_ui_searchhelp
  PUBLIC.


  INTERFACES /sct/qp_if_ui_callback.

  ALIASES get_callback_event FOR /sct/qp_if_ui_callback~get_callback_event.

  TYPES:
    BEGIN OF ts_token,
      key      TYPE string,
      text     TYPE string,
      visible  TYPE abap_bool,
      selkz    TYPE abap_bool,
      editable TYPE abap_bool,
    END OF ts_token.
  TYPES tt_token TYPE STANDARD TABLE OF ts_token WITH KEY key.
  TYPES:
    BEGIN OF tys_result,
      check_confirmed TYPE abap_bool,
      shlp_descr      TYPE shlp_descr,
      return_values   TYPE /sct/qp_qv_search_result_tt,
      t_range         TYPE RANGE OF string,
    END OF tys_result.
  TYPES tty_ddshdescr TYPE STANDARD TABLE OF ddshdescr WITH EMPTY KEY.
  TYPES:
    BEGIN OF ty_coll_shlp,
      shlp_descr TYPE shlp_descr,
      def_shlp   TYPE shlpname,
      def_text   TYPE ddtext,
      t_shlp     TYPE shlp_desct,
    END OF ty_coll_shlp.
  TYPES:
    BEGIN OF tys_input,
      selkz     TYPE abap_boolean,
      fieldname TYPE string,
      name      TYPE string,
      value     TYPE string,
      token     TYPE tt_token,
    END OF tys_input.
  TYPES tty_input TYPE STANDARD TABLE OF tys_input WITH EMPTY KEY.

  METHODS init IMPORTING iv_shlp         TYPE /sct/qp_shlp                          OPTIONAL
                         is_toe          TYPE /sct/qp_s_toe                         OPTIONAL
                         is_callback     TYPE /sct/qp_if_ui_callback=>ty_s_callback OPTIONAL
                         iv_value        TYPE ddshvalue                             OPTIONAL
                         iv_multi_result TYPE abap_bool                             OPTIONAL.

  METHODS get_data RETURNING VALUE(result) TYPE /sct/qp_t_toebuffer_value.
ENDINTERFACE.
