interface /SCT/QP_IF_UI_WIZARD
  public .


  interfaces /SCT/QP_IF_UI_APP .

  methods INIT
    importing
      !IS_CALLBACK type /SCT/QP_IF_UI_CALLBACK=>TY_S_CALLBACK optional
      !IV_OBJECT type STRING
      !IS_CURRENT_LOCATION type /SCT/QP_IF_UI_OBJLIST=>TY_S_CURRENT_LOCATION optional
      !IS_CONTROL type /SCT/QP_IF_UI_APP~TY_S_CONTROL .
endinterface.
