INTERFACE /sct/qp_if_ui_selection
  PUBLIC.


  INTERFACES /sct/qp_if_ui_app.
  INTERFACES if_serializable_object.

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
    BEGIN OF ty_s_input,
      selkz     TYPE abap_bool,
      fieldname TYPE string,
      name      TYPE string,
      group     TYPE string,
      value     TYPE string,
      shlp      TYPE shlpname,
      convexit  TYPE convexit,
      lowercase TYPE lowercase,
      token     TYPE tt_token,
    END OF ty_s_input.
  TYPES ty_t_input TYPE STANDARD TABLE OF ty_s_input WITH EMPTY KEY.
  TYPES:
    BEGIN OF ty_s_select,
*
      " Allgemein
      max_sel_count      TYPE i,
      max_bom_level      TYPE i,

**********************************************************************
* FELDER AUS /SCT/QP_R_SELECTION
*      guid                          TYPE string,
*      documenttype                  TYPE string,
*      nodenumber                    TYPE string,
*      nodeversion                   TYPE string,
*      nodenumberversion             TYPE string,
*      name                          TYPE string,
*      specificationtype             TYPE string,
*      itemtype                      TYPE string,
*      createdbyuser                 TYPE string,
      creationdate       TYPE string,
*      creationdate_d1    TYPE d,
*      creationdate_d2    TYPE d,
      creationtime       TYPE string,
*      lastchangedbyuser             TYPE string,
      lastchangedate     TYPE string,
*      lastchangedate_d1  TYPE d,
*      lastchangedate_d2  TYPE d,
      lastchangetime     TYPE t,
*      status                        TYPE string,
*      criticality                   TYPE string,
*      description                   TYPE string,
*      shorttext                     TYPE string,
*      mediumtext                    TYPE string,
*      originalguid                  TYPE string,
*      hierarchy                     TYPE string,
*      originalnodenodenumber        TYPE string,
*      originalnodenodeversion       TYPE string,
*      originalnodenodenumberversion TYPE string,
*      originalnodename              TYPE string,
*      originalspecificationtype     TYPE string,
*      salesdocument                 TYPE string,
*      salesdocumentitem             TYPE string,
*      schedulelinenumber            TYPE string,
*      purchasingdocument            TYPE string,
*      purchasingdocumentitem        TYPE string,
*      productionorder               TYPE string,
*      material                      TYPE string,
*      plant                         TYPE string,
*      productionversion             TYPE string,
*      inspectionlot                 TYPE string,

*      rng_guid                      TYPE RANGE OF string,
*      rng_documenttype              TYPE RANGE OF string,
*      rng_nodenumber                TYPE RANGE OF string,
*      rng_nodeversion               TYPE RANGE OF string,
*      rng_nodenumberversion         TYPE RANGE OF string,
*      rng_name                      TYPE RANGE OF string,
*      rng_specificationtype         TYPE RANGE OF string,
*      rng_itemtype                  TYPE RANGE OF string,
*      rng_createdbyuser             TYPE RANGE OF string,
*      rng_creationdate              TYPE RANGE OF string,
*      rng_creationtime              TYPE RANGE OF string,
*      rng_lastchangedbyuser         TYPE RANGE OF string,
*      rng_lastchangedate            TYPE RANGE OF string,
*      rng_status                    TYPE RANGE OF string,
*      rng_criticality               TYPE RANGE OF string,
*      rng_description               TYPE RANGE OF string,
*      rng_shorttext                 TYPE RANGE OF string,
*      rng_mediumtext                TYPE RANGE OF string,
*      rng_originalguid              TYPE RANGE OF string,
*      rng_hierarchy                 TYPE RANGE OF string,
*      rng_originalnodenodenumber    TYPE RANGE OF string,
*      rng_originalnodenodeversion   TYPE RANGE OF string,
**      rng_originalnodenodenumberversion TYPE string,
*      rng_originalnodename          TYPE RANGE OF string,
*      rng_originalspecificationtype TYPE RANGE OF string,
*      rng_salesdocument             TYPE RANGE OF string,
*      rng_salesdocumentitem         TYPE RANGE OF string,
*      rng_schedulelinenumber        TYPE RANGE OF string,
*      rng_purchasingdocument        TYPE RANGE OF string,
*      rng_purchasingdocumentitem    TYPE RANGE OF string,
*      rng_productionorder           TYPE RANGE OF string,
*      rng_material                  TYPE RANGE OF string,
*      rng_plant                     TYPE RANGE OF string,
*      rng_productionversion         TYPE RANGE OF string,
*      rng_inspectionlot             TYPE RANGE OF string,
    END OF ty_s_select.

  TYPES:
    BEGIN OF ty_s_token,
      key      TYPE string,
      text     TYPE string,
      visible  TYPE abap_bool,
      selkz    TYPE abap_bool,
      editable TYPE abap_bool,
    END OF ty_s_token.

  DATA ms_select    TYPE ty_s_select. " Selektionsfelder mit Inhalt
  DATA mt_selfields TYPE ty_t_input.  " Mögliche Selektionsfelder mit Attributen

*  DATA mr_select    TYPE REF TO ty_s_select. " Selektionsfelder mit Inhalt
*  DATA mr_selfields TYPE REF TO ty_t_input.  " Mögliche Selektionsfelder mit Attributen
ENDINTERFACE.
