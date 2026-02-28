model DosSeparadorsParaleloDesarroloV49_29b
  parameter Real V_sep = 17;
  parameter Real Q_agua = 83;
  parameter Real Q_petroleo = 20;

  parameter Real SP_general  = 75;
  parameter Real SP_petroleo = 54;

  // Controladores PI (más rápidos)
  Modelica.Blocks.Continuous.PI pidSep1General(k=4.0, T=15);
  Modelica.Blocks.Continuous.PI pidSep1Petroleo(k=4.5, T=15);
  Modelica.Blocks.Continuous.PI pidSep2General(k=4.0, T=15);
  Modelica.Blocks.Continuous.PI pidSep2Petroleo(k=4.5, T=15);

  model Separador
    parameter Real V = 17;
    input Real Q_in_agua;
    input Real Q_in_petroleo;
    input Real Q_out_agua;
    input Real Q_out_petroleo;

    Real nivelAgua(start=0.0);
    Real nivelPetroleo(start=0.0);

    Real nivelGeneral;
    Real nivelAgua_pct;
    Real nivelPetroleo_pct;
    Real nivelGeneral_pct;
  equation
    der(nivelAgua)     = (Q_in_agua - Q_out_agua)/3600 / V;
    der(nivelPetroleo) = (Q_in_petroleo - Q_out_petroleo)/3600 / V;

    nivelGeneral      = nivelAgua + nivelPetroleo;
    nivelAgua_pct     = (nivelAgua / V) * 100;
    nivelPetroleo_pct = (nivelPetroleo / V) * 100;
    nivelGeneral_pct  = (nivelGeneral / V) * 100;

    when nivelGeneral < 0 then reinit(nivelGeneral, 0); end when;
    when nivelGeneral > V then reinit(nivelGeneral, V); end when;
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

  sep1.Q_out_agua     = max(0, min(sep1.Q_in_agua, sep1.Q_in_agua * (1 + pidSep1General.y/100)));
  sep1.Q_out_petroleo = max(0, min(sep1.Q_in_petroleo, sep1.Q_in_petroleo * (1 + pidSep1Petroleo.y/100)));

  sep2.Q_out_agua     = max(0, min(sep2.Q_in_agua, sep2.Q_in_agua * (1 + pidSep2General.y/100)));
  sep2.Q_out_petroleo = max(0, min(sep2.Q_in_petroleo, sep2.Q_in_petroleo * (1 + pidSep2Petroleo.y/100)));

end DosSeparadorsParaleloDesarroloV49_29b;
