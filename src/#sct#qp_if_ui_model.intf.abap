interface /SCT/QP_IF_UI_MODEL
  public .


  class-methods GET_INSTANCE
    returning
      value(RO_INSTANCE) type ref to /SCT/QP_IF_UI_MODEL .
  methods GET_HIERARCHY
    importing
      !IV_OGUID type /SCT/QP_OGUID
      !IV_GUID type /SCT/QP_GUID
    exporting
      !ET_BASE type /SCT/QP_TREF_BASE
    returning
      value(RR_BASE) type ref to /SCT/QP_S_BASE .
  methods GET_BASE
    importing
      !IV_GUID type /SCT/QP_GUID
      !IV_OGUID type /SCT/QP_OGUID
    returning
      value(RR_BASE) type ref to /SCT/QP_S_BASE .
  methods GET_BASE_PARENTS
    importing
      !IR_BASE type ref to /SCT/QP_S_BASE
    returning
      value(RTREF_BASE) type /SCT/QP_TREF_BASE .
  methods IS_BASE_ACTION_ALLOWED
    importing
      !IV_ACTION type /SCT/QP_ACTION
      !IR_BASE type ref to /SCT/QP_S_BASE
    returning
      value(RV_ALLOWED) type ABAP_BOOL
    raising
      /SCT/QP_CX_ERROR .
  methods GET_BASE_PARENT_RESOLVE_VBLOCK
    importing
      !IR_BASE type ref to /SCT/QP_S_BASE
    returning
      value(RR_BASE_PARENT) type ref to /SCT/QP_S_BASE
    raising
      /SCT/QP_CX_ERROR .
endinterface.
