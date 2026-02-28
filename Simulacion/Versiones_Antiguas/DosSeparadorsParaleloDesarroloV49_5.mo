model DosSeparadorsParaleloDesarroloV49_5
  parameter Real V_sep = 17;
  parameter Real Q_agua = 83;
  parameter Real Q_petroleo = 20;
  parameter Real Q_liquidos = Q_agua + Q_petroleo;
  parameter Real Q_gas = 150;

  // Setpoints
  parameter Real SP_sep1 = 75 "Setpoint nivel general sep1 (%)";
  parameter Real SP_sep2 = 54 "Setpoint nivel general sep2 (%)";

  // Controladores PI
  Modelica.Blocks.Continuous.PI pidSep1(k=1, T=60);
  Modelica.Blocks.Continuous.PI pidSep2(k=1, T=60);

  // Modelo de separador
  model Separador
    parameter Real V = 17;
    input Real Q_in;
    input Real Q_out;
    Real nivel(start=0.5);
    Real nivel_pct;
    Real nivelPetroleo;
    Real nivelPetroleo_pct;
    Real tiempoResidencia;
    Real eficiencia;
    parameter Real SP = 75;
  equation
    der(nivel) = (Q_in - Q_out)/3600 / V;
    nivel_pct = min(100, max(0, nivel*100));
    nivelPetroleo = 0.54*nivel;
    nivelPetroleo_pct = min(100, max(0, nivelPetroleo*100));
    tiempoResidencia = if Q_out > 0 then (nivel*V)/(Q_out/3600) else 0;
    eficiencia = 100 - abs(nivel_pct - SP);
    when nivel < 0 then reinit(nivel, 0); end when;
    when nivel > 1 then reinit(nivel, 1); end when;
  end Separador;

  Separador sep1(V=V_sep, SP=SP_sep1);
  Separador sep2(V=V_sep, SP=SP_sep2);

equation
  sep1.Q_in = Q_liquidos/2;
  sep2.Q_in = Q_liquidos/2;

  // Ambos regulan nivel general contra su SP
  pidSep1.u = sep1.nivel_pct - SP_sep1;
  pidSep2.u = sep2.nivel_pct - SP_sep2;

  sep1.Q_out = Q_liquidos/2 + pidSep1.y;
  sep2.Q_out = Q_liquidos/2 + pidSep2.y;

end DosSeparadorsParaleloDesarroloV49_5;
