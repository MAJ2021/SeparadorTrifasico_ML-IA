model DosSeparadorsParaleloDesarroloV49_2
  // Parámetros generales
  parameter Real V_sep = 17 "Volumen útil de cada separador [m3]";
  parameter Real Q_agua = 83 "Caudal agua [m3/h]";
  parameter Real Q_petroleo = 20 "Caudal petróleo [m3/h]";
  parameter Real Q_liquidos = Q_agua + Q_petroleo;
  parameter Real Q_gas = 150 "Caudal gas promedio [m3/h]";

  // Setpoints en porcentaje
  parameter Real SP_general = 0.75 "Setpoint nivel general (75 %)";
  parameter Real SP_petroleo = 0.54 "Setpoint nivel petróleo (54 %)";

  // Controladores PI
  Modelica.Blocks.Continuous.PI pidNivelGeneral(k=1, T=60);
  Modelica.Blocks.Continuous.PI pidNivelPetroleo(k=1, T=60);

  // Modelo interno de separador
  model Separador
    parameter Real V = 17;
    input Real Q_in;
    input Real Q_out;
    Real nivel(start=0.5) "Nivel líquido (0..1)";
    Real nivelPetroleo(start=0.3) "Nivel petróleo (0..1)";
    Real nivel_pct;
    Real nivelPetroleo_pct;
  equation
    // Balance de volumen líquido
    der(nivel) = (Q_in - Q_out)/3600 / V;

    // Nivel de petróleo como fracción del nivel total
    nivelPetroleo = 0.54*nivel;

    // Conversión a porcentaje con saturación
    nivel_pct = min(100, max(0, nivel*100));
    nivelPetroleo_pct = min(100, max(0, nivelPetroleo*100));

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

  // Error respecto al setpoint en %
  pidNivelGeneral.u = (sep1.nivel_pct - SP_general*100);
  pidNivelPetroleo.u = (sep2.nivelPetroleo_pct - SP_petroleo*100);

  // Salidas reguladas
  sep1.Q_out = pidNivelGeneral.y * Q_liquidos/2;
  sep2.Q_out = pidNivelPetroleo.y * Q_liquidos/2;

end DosSeparadorsParaleloDesarroloV49_2;
