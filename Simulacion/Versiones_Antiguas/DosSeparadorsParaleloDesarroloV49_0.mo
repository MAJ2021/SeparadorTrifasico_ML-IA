model DosSeparadorsParaleloDesarroloV49_0
  // Parámetros generales
  parameter Real V_sep = 17 "Volumen útil de cada separador [m3]";
  parameter Real Q_agua = 83 "Caudal agua [m3/h]";
  parameter Real Q_petroleo = 20 "Caudal petróleo [m3/h]";
  parameter Real Q_liquidos = Q_agua + Q_petroleo;
  parameter Real Q_gas = 150 "Caudal gas promedio [m3/h]";

  // Controladores PI (de librería estándar)
  Modelica.Blocks.Continuous.PI pidNivelGeneral(k=1, T=60);
  Modelica.Blocks.Continuous.PI pidNivelPetroleo(k=1, T=60);

  // Modelo de separador definido dentro del mismo archivo
  model Separador
    parameter Real V = 17 "Volumen útil [m3]";
    input Real Q_in "Caudal líquido de entrada [m3/h]";
    input Real Q_out "Caudal líquido de salida [m3/h]";
    Real nivel(start=0.5) "Nivel líquido (0..1)";
    Real nivelPetroleo(start=0.3) "Nivel petróleo (0..1)";
  equation
    // Balance de volumen líquido: entrada - salida
    der(nivel) = (Q_in/3600 - Q_out/3600)/V;

    // Nivel de petróleo como fracción del nivel total (simplificación)
    nivelPetroleo = 0.54*nivel;

    // Restricciones: nivel entre 0 y 1
    when nivel < 0 then
      reinit(nivel, 0);
    end when;

    when nivel > 1 then
      reinit(nivel, 1);
    end when;
  end Separador;

  // Dos separadores en paralelo
  Separador sep1(V=V_sep);
  Separador sep2(V=V_sep);

equation
  // Distribución de caudales de entrada
  sep1.Q_in = Q_liquidos/2;
  sep2.Q_in = Q_liquidos/2;

  // Salida controlada por los PI (simplificación)
  sep1.Q_out = pidNivelGeneral.y * Q_liquidos/2;
  sep2.Q_out = pidNivelPetroleo.y * Q_liquidos/2;

  // Entradas de control
  pidNivelGeneral.u = sep1.nivel;
  pidNivelPetroleo.u = sep2.nivelPetroleo;

end DosSeparadorsParaleloDesarroloV49_0;
