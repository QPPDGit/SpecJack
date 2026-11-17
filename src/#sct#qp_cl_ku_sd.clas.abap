CLASS /sct/qp_cl_ku_sd DEFINITION
  PUBLIC
  INHERITING FROM /sct/qp_cl_gts FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS get_instance IMPORTING iv_salesorder TYPE vbeln
                                         iv_item       TYPE posnr_va OPTIONAL
                               RETURNING VALUE(result) TYPE REF TO /sct/qp_cl_ku_sd.

    METHODS constructor.
    METHODS set_data    IMPORTING is_data   TYPE /sct/qp_s_ecc_doc_link.

    METHODS data_change IMPORTING ir_struct TYPE REF TO data.

  PROTECTED SECTION.
    METHODS get_qppd_element IMPORTING iv_fieldname  TYPE string
                             RETURNING VALUE(result) TYPE /sct/qp_element.

    DATA ms_doc_link TYPE /sct/qp_s_ecc_doc_link.
    DATA mo_vart     TYPE REF TO /sct/qp_if_vart.
ENDCLASS.



CLASS /SCT/QP_CL_KU_SD IMPLEMENTATION.


  METHOD get_instance.
    /sct/qp_cl_factory=>get_instances( IMPORTING " eo_model  = DATA(lo_model)
                                       " eo_conv   = DATA(lo_conv)
                                                 eo_appbus = DATA(lo_appbus) ).

    IF iv_item IS INITIAL.
      DATA(ls_doc) = lo_appbus->get_ecc_doc_for_vbak( iv_vbeln = iv_salesorder ).
    ELSE.
      ls_doc = lo_appbus->get_ecc_doc_for_vbap( iv_vbeln = iv_salesorder
                                                iv_posnr = iv_item  ).
    ENDIF.

    lo_appbus->get_ecc_links_for_docs( EXPORTING it_docs      = VALUE #( ( ls_doc )  )
                                       IMPORTING et_doc_links = DATA(lt_doc_link) ).

    IF lines( lt_doc_link[]  ) > 1.
      DATA(ls_doc_link) = VALUE #( lt_doc_link[ vart = 'DEMAND' ] ).
      IF ls_doc_link IS INITIAL.
        ls_doc_link = lt_doc_link[ 1 ].
      ENDIF.
    ELSE.
      ls_doc_link = VALUE #( lt_doc_link[ 1 ] OPTIONAL ).
    ENDIF.

    IF ls_doc_link IS NOT INITIAL.
      /sct/qp_cl_factory=>get_instance( EXPORTING iv_classname      = '/SCT/QP_CL_KU_SD'
                                                  iv_classcondition = |{ ls_doc-dockey }{ ls_doc-doctype }|
                                        CHANGING  co_instance       = result ).

      result->set_data( ls_doc_link ).
    ENDIF.
  ENDMETHOD.


  METHOD data_change.
    IF mo_vart IS NOT BOUND.
      RETURN.
    ENDIF.
    DATA(lo_struct) = CAST cl_abap_datadescr( cl_abap_structdescr=>describe_by_data_ref( ir_struct ) ).

    DATA lr_qppd_data TYPE REF TO data.
    CREATE DATA lr_qppd_data TYPE HANDLE lo_struct.

    DATA(lt_val) = VALUE /sct/qp_ts_qvc_val_data( ).
    DATA(lt_comp) = mo_tools->get_struct_comp( io_data = ir_struct ).

    " Assumption: All fields are QPPD fields
    " TRIM prefix and suffix
    LOOP AT lt_comp ASSIGNING FIELD-SYMBOL(<comp>).
      <comp>-x030l-refname = get_qppd_element( <comp>-name ).
      lr_qppd_data->(<comp>-name) = mo_vart->get_value( CONV #( <comp>-x030l-refname ) ).

      IF lr_qppd_data->(<comp>-name) <> ir_struct->(<comp>-name).
        " SD and QPPD are not synched ( manual change in SD )
        INSERT VALUE #( element = <comp>-x030l-refname
                        value   = CONV #( ir_struct->(<comp>-name)  ) ) INTO TABLE lt_val.
      ENDIF.
    ENDLOOP.

    IF lt_val IS NOT INITIAL.
      " Make changes in QPPD
      mo_vart->change( it_change = VALUE #( ( val = lt_val  ) ) ).
      " Read changed data
      LOOP AT lt_comp ASSIGNING <comp>.
        ir_struct->(<comp>-name) = mo_vart->get_value( CONV #( <comp>-x030l-refname ) ).
      ENDLOOP.
    ENDIF.
  ENDMETHOD.


  METHOD set_data.
    IF is_data IS INITIAL.
      RETURN.
    ENDIF.
    ms_doc_link = is_data.

    IF ms_doc_link-guid IS NOT INITIAL.
      mo_vart ?= /sct/qp_cl_vart=>get_instance_vart( iv_guid = ms_doc_link-guid ).
    ENDIF.
  ENDMETHOD.


  METHOD constructor.
    super->constructor( ).
    /sct/qp_cl_factory=>get_instances( IMPORTING eo_bus   = mo_bus
                                                 eo_tools = mo_tools ).
  ENDMETHOD.


  METHOD get_qppd_element.
    SPLIT iv_fieldname AT '_' INTO TABLE DATA(lt_sub).
    DELETE lt_sub INDEX lines( lt_sub ).
    DELETE lt_sub INDEX 1.
    IF lines( lt_sub ) = 1.
      result = lt_sub[ 1 ].
    ELSE.
      CLEAR result.
      LOOP AT lt_sub ASSIGNING FIELD-SYMBOL(<sub>).
        IF result IS INITIAL.
          result = <sub>.
        ELSE.
          result = |{ result }_{ <sub> }|.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
