model DosSeparadorsParaleloDesarroloV49_6
  parameter Real V_sep = 17;
  parameter Real Q_agua = 83;
  parameter Real Q_petroleo = 20;
  parameter Real Q_liquidos = Q_agua + Q_petroleo;
  parameter Real Q_gas = 150;

  // Setpoints (iguales para ambos separadores)
  parameter Real SP_general = 75 "Setpoint nivel general (%)";
  parameter Real SP_petroleo = 54 "Setpoint nivel petróleo (%)";

  // Controladores PI
  Modelica.Blocks.Continuous.PI pidSep1General(k=1, T=60);
  Modelica.Blocks.Continuous.PI pidSep1Petroleo(k=1, T=60);
  Modelica.Blocks.Continuous.PI pidSep2General(k=1, T=60);
  Modelica.Blocks.Continuous.PI pidSep2Petroleo(k=1, T=60);

  // Modelo de separador
  model Separador
    parameter Real V = 17;
    input Real Q_in;
    input Real Q_out;
    Real nivel(start=0.5);
    Real nivelPetroleo(start=0.3);
    Real nivel_pct;
    Real nivelPetroleo_pct;
  equation
    der(nivel) = (Q_in - Q_out)/3600 / V;
    nivelPetroleo = 0.54*nivel;
    nivel_pct = min(100, max(0, nivel*100));
    nivelPetroleo_pct = min(100, max(0, nivelPetroleo*100));
    when nivel < 0 then reinit(nivel, 0); end when;
    when nivel > 1 then reinit(nivel, 1); end when;
  end Separador;

  Separador sep1(V=V_sep);
  Separador sep2(V=V_sep);

equation
  sep1.Q_in = Q_liquidos/2;
  sep2.Q_in = Q_liquidos/2;

  // Ambos separadores regulan contra los mismos setpoints
  pidSep1General.u   = sep1.nivel_pct - SP_general;
  pidSep1Petroleo.u  = sep1.nivelPetroleo_pct - SP_petroleo;
  pidSep2General.u   = sep2.nivel_pct - SP_general;
  pidSep2Petroleo.u  = sep2.nivelPetroleo_pct - SP_petroleo;

  // Salidas reguladas (ejemplo: se combinan las dos acciones)
  sep1.Q_out = Q_liquidos/2 + pidSep1General.y + pidSep1Petroleo.y;
  sep2.Q_out = Q_liquidos/2 + pidSep2General.y + pidSep2Petroleo.y;

end DosSeparadorsParaleloDesarroloV49_6;
