model DosSeparadorsParaleloDesarroloV49_28_4
  parameter Real V_sep = 17;
  parameter Real Q_agua = 83;        // caudal horario
  parameter Real Q_petroleo = 20;    // caudal horario

  // Setpoints correctos
  parameter Real SP_general  = 75;
  parameter Real SP_petroleo = 54;

  // Controladores PI (moderados)
  Modelica.Blocks.Continuous.PI pidSep1General(k=0.8, T=200);
  Modelica.Blocks.Continuous.PI pidSep1Petroleo(k=0.8, T=200);
  Modelica.Blocks.Continuous.PI pidSep2General(k=0.8, T=200);
  Modelica.Blocks.Continuous.PI pidSep2Petroleo(k=0.8, T=200);

  // Coeficientes de válvula (ajustables)
  parameter Real Kv_agua = 1.0;
  parameter Real Kv_petroleo = 1.0;

  model Separador
    parameter Real V = 17;
    input Real Q_in_agua;
    input Real Q_in_petroleo;
    output Real Q_out_agua;
    output Real Q_out_petroleo;

    // Arranque desde cero
    Real nivelAgua(start=0.0);
    Real nivelPetroleo(start=0.0);

    Real nivelGeneral;
    Real nivelAgua_pct;
    Real nivelPetroleo_pct;
    Real nivelGeneral_pct;

    // Descarga de emergencia
    Real Q_emergencia(start=0.0);
  equation
    der(nivelAgua)     = (Q_in_agua - Q_out_agua)/3600 / V;
    der(nivelPetroleo) = (Q_in_petroleo - Q_out_petroleo)/3600 / V;

    nivelGeneral      = nivelAgua + nivelPetroleo;

    nivelAgua_pct     = nivelAgua*100;
    nivelPetroleo_pct = nivelPetroleo*100;
    nivelGeneral_pct  = nivelGeneral*100;

    // Rebalse físico: si nivel > 100%, se abre descarga de emergencia
    when nivelGeneral_pct > 100 then
      Q_emergencia = (nivelGeneral_pct - 100)*V;  // proporcional al exceso
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

  // ✅ Nueva lógica de válvulas
  sep1.Q_out_agua     = max(0, Kv_agua * pidSep1General.y + sep1.Q_emergencia);
  sep1.Q_out_petroleo = max(0, Kv_petroleo * pidSep1Petroleo.y);

  sep2.Q_out_agua     = max(0, Kv_agua * pidSep2General.y + sep2.Q_emergencia);
  sep2.Q_out_petroleo = max(0, Kv_petroleo * pidSep2Petroleo.y);

end DosSeparadorsParaleloDesarroloV49_28_4;
