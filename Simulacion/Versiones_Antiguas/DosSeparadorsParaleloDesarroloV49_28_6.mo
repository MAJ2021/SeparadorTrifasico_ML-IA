model DosSeparadorsParaleloDesarroloV49_28_6
  parameter Real V_sep = 17;
  parameter Real Q_agua = 83;        // caudal horario
  parameter Real Q_petroleo = 20;    // caudal horario

  // Setpoints de control [% del volumen del separador]
  parameter Real SP_general  = 75;   // nivel total (agua+oil)
  parameter Real SP_petroleo = 54;   // nivel de petróleo

  // ✅ Controladores PI ajustados
  // Agua (general): menos agresivo → sube nivel hacia 75%
  Modelica.Blocks.Continuous.PI pidSep1General(k=0.6, T=250);
  Modelica.Blocks.Continuous.PI pidSep2General(k=0.6, T=250);

  // Petróleo: más agresivo → baja nivel hacia 54%
  Modelica.Blocks.Continuous.PI pidSep1Petroleo(k=1.2, T=150);
  Modelica.Blocks.Continuous.PI pidSep2Petroleo(k=1.2, T=150);

  // Coeficientes de válvula
  parameter Real Kv_agua = 1.0;
  parameter Real Kv_petroleo = 1.0;

  model Separador
    parameter Real V = 17;
    input Real Q_in_agua;
    input Real Q_in_petroleo;
    output Real Q_out_agua;
    output Real Q_out_petroleo;

    Real nivelAgua(start=0.0);
    Real nivelPetroleo(start=0.0);

    Real nivelGeneral;
    Real nivelAgua_pct;
    Real nivelPetroleo_pct;
    Real nivelGeneral_pct;

    Real Q_emergencia(start=0.0);
  equation
    der(nivelAgua)     = (Q_in_agua - Q_out_agua)/3600 / V;
    der(nivelPetroleo) = (Q_in_petroleo - Q_out_petroleo)/3600 / V;

    nivelGeneral      = nivelAgua + nivelPetroleo;

    nivelAgua_pct     = nivelAgua*100;
    nivelPetroleo_pct = nivelPetroleo*100;
    nivelGeneral_pct  = nivelGeneral*100;

    // Rebalse físico
    when nivelGeneral_pct > 100 then
      Q_emergencia = (nivelGeneral_pct - 100)*V;
    elsewhen nivelGeneral_pct <= 100 then
      Q_emergencia = 0;
    end when;
  end Separador;

  Separador sep1(V=V_sep);
  Separador sep2(V=V_sep);

equation
  sep1.Q_in_agua     = Q_agua/2;
  sep1.Q_in_petroleo = Q_petroleo/2;
  sep2.Q_in_agua     = Q_agua/2;
  sep2.Q_in_petroleo = Q_petroleo/2;

  pidSep1General.u   = sep1.nivelGeneral_pct - SP_general;
  pidSep1Petroleo.u  = sep1.nivelPetroleo_pct - SP_petroleo;
  pidSep2General.u   = sep2.nivelGeneral_pct - SP_general;
  pidSep2Petroleo.u  = sep2.nivelPetroleo_pct - SP_petroleo;

  sep1.Q_out_agua     = max(0, Kv_agua * pidSep1General.y + sep1.Q_emergencia);
  sep1.Q_out_petroleo = max(0, Kv_petroleo * pidSep1Petroleo.y);

  sep2.Q_out_agua     = max(0, Kv_agua * pidSep2General.y + sep2.Q_emergencia);
  sep2.Q_out_petroleo = max(0, Kv_petroleo * pidSep2Petroleo.y);

end DosSeparadorsParaleloDesarroloV49_28_6;
