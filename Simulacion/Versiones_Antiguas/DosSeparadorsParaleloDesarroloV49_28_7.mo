model DosSeparadorsParaleloDesarroloV49_28_7
  parameter Real V_sep = 17;
  parameter Real Q_agua = 83;        // caudal horario
  parameter Real Q_petroleo = 20;    // caudal horario

  // Setpoints de control [% del volumen del separador]
  parameter Real SP_general  = 75;
  parameter Real SP_petroleo = 54;

  // Controladores PI
  Modelica.Blocks.Continuous.PI pidSep1General(k=0.8, T=200);
  Modelica.Blocks.Continuous.PI pidSep1Petroleo(k=0.8, T=200);
  Modelica.Blocks.Continuous.PI pidSep2General(k=0.8, T=200);
  Modelica.Blocks.Continuous.PI pidSep2Petroleo(k=0.8, T=200);

  // Coeficientes de válvula
  parameter Real Kv_agua = 1.0;
  parameter Real Kv_petroleo = 1.0;

  model Separador
    parameter Real V = 17;
    input Real Q_in_agua;
    input Real Q_in_petroleo;
    input Real Q_out_agua;
    input Real Q_out_petroleo;

    Real nivelAgua(start=0.0);       // volumen agua [m3]
    Real nivelPetroleo(start=0.0);   // volumen petróleo [m3]

    Real nivelGeneral;
    Real nivelAgua_pct;
    Real nivelPetroleo_pct;
    Real nivelGeneral_pct;
  equation
    // Balance dinámico de volúmenes
    der(nivelAgua)     = (Q_in_agua - Q_out_agua)/3600;
    der(nivelPetroleo) = (Q_in_petroleo - Q_out_petroleo)/3600;

    nivelGeneral      = nivelAgua + nivelPetroleo;

    // Escalado correcto en %
    nivelAgua_pct     = (nivelAgua/V)*100;
    nivelPetroleo_pct = (nivelPetroleo/V)*100;
    nivelGeneral_pct  = (nivelGeneral/V)*100;
  end Separador;

  Separador sep1(V=V_sep);
  Separador sep2(V=V_sep);

equation
  // División de caudales de entrada entre separadores
  sep1.Q_in_agua     = Q_agua/2;
  sep1.Q_in_petroleo = Q_petroleo/2;
  sep2.Q_in_agua     = Q_agua/2;
  sep2.Q_in_petroleo = Q_petroleo/2;

  // Señales de control
  pidSep1General.u   = sep1.nivelGeneral_pct - SP_general;
  pidSep1Petroleo.u  = sep1.nivelPetroleo_pct - SP_petroleo;
  pidSep2General.u   = sep2.nivelGeneral_pct - SP_general;
  pidSep2Petroleo.u  = sep2.nivelPetroleo_pct - SP_petroleo;

  // ✅ Caudales de salida calculados en el modelo principal
  sep1.Q_out_agua     = Kv_agua * max(0, pidSep1General.y) * (sep1.nivelAgua/V_sep);
  sep1.Q_out_petroleo = Kv_petroleo * max(0, pidSep1Petroleo.y) * (sep1.nivelPetroleo/V_sep);

  sep2.Q_out_agua     = Kv_agua * max(0, pidSep2General.y) * (sep2.nivelAgua/V_sep);
  sep2.Q_out_petroleo = Kv_petroleo * max(0, pidSep2Petroleo.y) * (sep2.nivelPetroleo/V_sep);


end DosSeparadorsParaleloDesarroloV49_28_7;
