model DosSeparadorsParaleloDesarroloV49_3b
  // Parámetros generales
  parameter Real V_sep = 17 "Volumen útil de cada separador [m3]";
  parameter Real Q_agua = 83 "Caudal agua [m3/h]";
  parameter Real Q_petroleo = 20 "Caudal petróleo [m3/h]";
  parameter Real Q_liquidos = Q_agua + Q_petroleo;
  parameter Real Q_gas = 150 "Caudal gas promedio [m3/h]";

  // Setpoints en porcentaje
  parameter Real SP_sep1 = 75 "Setpoint nivel sep1 (%)";
  parameter Real SP_sep2 = 54 "Setpoint nivel sep2 (%)";

  // Controladores PI
  Modelica.Blocks.Continuous.PI pidSep1(k=1, T=60);
  Modelica.Blocks.Continuous.PI pidSep2(k=1, T=60);

  // Modelo interno de separador
  model Separador
    parameter Real V = 17;
    input Real Q_in;
    input Real Q_out;
    Real nivel(start=0.5) "Nivel líquido (0..1)";
    Real nivel_pct;
  equation
    // Balance de volumen líquido
    der(nivel) = (Q_in - Q_out)/3600 / V;

    // Conversión a porcentaje con saturación
    nivel_pct = min(100, max(0, nivel*100));

    // Restricciones físicas
    when nivel < 0 then
      reinit(nivel, 0);
    end when;

    when nivel > 1 then
      reinit(nivel, 1);
    end when;
  end Separador;

  // Instancias de separadores
  Separador sep1(V=V_sep);
  Separador sep2(V=V_sep);

equation
  // Entradas
  sep1.Q_in = Q_liquidos/2;
  sep2.Q_in = Q_liquidos/2;

  // Errores respecto a sus setpoints
  pidSep1.u = sep1.nivel_pct - SP_sep1;
  pidSep2.u = sep2.nivel_pct - SP_sep2;

  // Salidas reguladas
  sep1.Q_out = Q_liquidos/2 + pidSep1.y;
  sep2.Q_out = Q_liquidos/2 + pidSep2.y;

end DosSeparadorsParaleloDesarroloV49_3b;
