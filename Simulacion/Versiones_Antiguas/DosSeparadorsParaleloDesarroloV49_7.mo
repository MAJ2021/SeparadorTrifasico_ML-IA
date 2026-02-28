model DosSeparadorsParaleloDesarroloV49_7
  parameter Real V_sep = 17;
  parameter Real Q_agua = 83;
  parameter Real Q_petroleo = 20;
  parameter Real Q_liquidos = Q_agua + Q_petroleo;
  parameter Real Q_gas = 150;

  // Setpoints (reales de planta)
  parameter Real SP_general = 75 "Setpoint nivel general (%)";
  parameter Real SP_petroleo = 54 "Setpoint nivel petróleo (%)";

  // Controladores PI
  Modelica.Blocks.Continuous.PI pidSep1General(k=0.5, T=120);
  Modelica.Blocks.Continuous.PI pidSep2Petroleo(k=0.5, T=120);

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
    nivel_pct = nivel*100;              // sin recorte artificial
    nivelPetroleo_pct = nivelPetroleo*100;
    when nivel < 0 then reinit(nivel, 0); end when;
    when nivel > 1 then reinit(nivel, 1); end when;
  end Separador;

  Separador sep1(V=V_sep);
  Separador sep2(V=V_sep);

equation
  sep1.Q_in = Q_liquidos/2;
  sep2.Q_in = Q_liquidos/2;

  // Controladores con setpoints reales
  pidSep1General.u  = sep1.nivel_pct - SP_general;
  pidSep2Petroleo.u = sep2.nivelPetroleo_pct - SP_petroleo;

  // Salidas reguladas como válvula proporcional
  sep1.Q_out = sep1.Q_in * (1 + pidSep1General.y/100);
  sep2.Q_out = sep2.Q_in * (1 + pidSep2Petroleo.y/100);

end DosSeparadorsParaleloDesarroloV49_7;
