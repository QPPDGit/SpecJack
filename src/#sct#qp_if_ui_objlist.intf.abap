INTERFACE /sct/qp_if_ui_objlist
  PUBLIC.


  INTERFACES /sct/qp_if_ui_app.
  INTERFACES if_serializable_object.

  TYPES:
    BEGIN OF ENUM ty_list_type,
      object_list_item,
      custom_list_item,
    END OF ENUM ty_list_type.
  TYPES:
    BEGIN OF ty_marker,
      visible    TYPE abap_bool,
      visibility TYPE string,
      type       TYPE string,
      info       TYPE string,
    END OF ty_marker.
  TYPES:
    BEGIN OF ty_s_objectlist,
      is_selected   TYPE abap_bool,
      key           TYPE /sct/qp_guid,
      oguid         TYPE /sct/qp_guid,
      guid          TYPE /sct/qp_guid,
      pguid         TYPE /sct/qp_guid,
      vnrvvs        TYPE string,
      vart          TYPE /sct/qp_vart,
      vtyp          TYPE /sct/qp_vtyp,
      text          TYPE /sct/qp_varttyptext,
      vname         TYPE string,
      istat         TYPE string,
      icon          TYPE string,
      state         TYPE string,
      vtext         TYPE string,
      type          TYPE string,
      workmode      TYPE /sct/qp_workmode,
      markervisible TYPE abap_bool,
      eqeuname      TYPE eqeuname,
      image_src     TYPE string,
      relattyp      TYPE /sct/qp_relattyp,
      marker        TYPE ty_marker,
      highlight     TYPE string,
      drill_vis     TYPE abap_bool,
      minus_vis     TYPE abap_bool,
      sortkr        TYPE string,
*      navigated   TYPE abap_bool,
*      nodes       TYPE STANDARD TABLE OF ty_s_tree2 WITH DEFAULT KEY,
    END OF ty_s_objectlist.
*  TYPES:
*    BEGIN OF ty_s_vartlist,
*      vart TYPE /sct/qp_vart,
*    END OF ty_s_vartlist .
  TYPES ty_t_objectlist TYPE STANDARD TABLE OF ty_s_objectlist WITH DEFAULT KEY.
  TYPES:
*  TYPES:
*    ty_t_vartlist TYPE STANDARD TABLE OF ty_s_vartlist WITH DEFAULT KEY .
    BEGIN OF ty_s_breadcrumbs,
      oguid     TYPE /sct/qp_oguid,
      guid      TYPE /sct/qp_guid,
      name      TYPE string,
      navigated TYPE abap_bool,
    END OF ty_s_breadcrumbs.
  TYPES ty_t_breadcrumbs TYPE STANDARD TABLE OF ty_s_breadcrumbs WITH DEFAULT KEY.
  TYPES:
    BEGIN OF ty_s_current_location,
      oguid   TYPE /sct/qp_oguid,
      guid    TYPE /sct/qp_guid,
      name    TYPE string,
      show_cl TYPE abap_bool,
    END OF ty_s_current_location.

  DATA mt_object_list     TYPE ty_t_objectlist.
  DATA mr_object_list     TYPE REF TO ty_t_objectlist.
  DATA mt_object_selected TYPE ty_t_objectlist.

  METHODS is_fcode_excluded IMPORTING ir_base         TYPE REF TO /sct/qp_s_base
                                      iv_action       TYPE /sct/qp_action
                            RETURNING VALUE(r_return) TYPE abap_bool.

  METHODS do_add_navlist_item IMPORTING io_parent       TYPE REF TO /sct/au5_cl_xml_view
                                        iv_text         TYPE clike OPTIONAL
                                        iv_icon         TYPE clike OPTIONAL
                                        iv_select       TYPE clike OPTIONAL
                                        iv_href         TYPE clike OPTIONAL
                                        iv_key          TYPE clike OPTIONAL
                                        iv_expanded     TYPE clike OPTIONAL
                                        iv_selectable   TYPE clike OPTIONAL
                              RETURNING VALUE(r_result) TYPE REF TO /sct/au5_cl_xml_view.

  METHODS do_add_navlist_group IMPORTING io_parent       TYPE REF TO /sct/au5_cl_xml_view
                                         iv_text         TYPE clike OPTIONAL
                                         iv_icon         TYPE clike OPTIONAL
                                         iv_select       TYPE clike OPTIONAL
                                         iv_href         TYPE clike OPTIONAL
                                         iv_key          TYPE clike OPTIONAL
                                         iv_has_expander TYPE clike OPTIONAL
                                         iv_expanded     TYPE clike OPTIONAL
                               RETURNING VALUE(r_result) TYPE REF TO /sct/au5_cl_xml_view.

  METHODS do_duplicate IMPORTING iv_guid TYPE string
                       RAISING
                         /sct/qp_cx_error.
  METHODS do_delete    IMPORTING iv_guid TYPE string
                       RAISING
                         /sct/qp_cx_error.

  METHODS do_add_menu_item IMPORTING io_parent       TYPE REF TO /sct/au5_cl_xml_view
                                     iv_press        TYPE clike OPTIONAL
                                     iv_text         TYPE clike OPTIONAL
                                     iv_icon         TYPE clike OPTIONAL
                           RETURNING VALUE(r_result) TYPE REF TO /sct/au5_cl_xml_view.

  METHODS do_add_menu_item_group IMPORTING io_parent            TYPE REF TO /sct/au5_cl_xml_view
                                           iv_itemselectionmode TYPE clike OPTIONAL
                                 RETURNING VALUE(r_result)      TYPE REF TO /sct/au5_cl_xml_view.

  METHODS do_set_navigated IMPORTING iv_guid TYPE /sct/qp_guid.

  METHODS do_popover IMPORTING iv_guid  TYPE /sct/qp_guid
                               iv_oguid TYPE /sct/qp_oguid
                               iv_id    TYPE string
                     RAISING
                       /sct/qp_cx_error.
ENDINTERFACE.
