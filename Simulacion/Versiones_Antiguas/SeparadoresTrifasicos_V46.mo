model SeparadoresTrifasicos_V46
  // Parámetros generales
  parameter Real V_sep   = 17.0 "Volumen de cada separador m3";
  parameter Real Qin_agua_dia = 2000.0 "Producción agua m3/día";
  parameter Real Qin_oil_dia  = 440.0 "Producción oil m3/día (promedio)";
  parameter Real Qin_gas_dia  = 4000.0 "Producción gas m3/día (promedio)";
  parameter Real T_op = 57 "Temperatura °C";
  parameter Real P_gas = 3.5 "Presión bar";

  // Conversión a caudales en m3/s
  parameter Real Qin_agua_base = Qin_agua_dia/86400;
  parameter Real Qin_oil_base  = Qin_oil_dia/86400;
  parameter Real Qin_gas_base  = Qin_gas_dia/86400;

  // Estados de cada separador
  Real V_agua1(start=0, min=0, max=V_sep);
  Real V_oil1(start=0, min=0, max=V_sep);
  Real V_agua2(start=0, min=0, max=V_sep);
  Real V_oil2(start=0, min=0, max=V_sep);

  // Caudales de entrada y salida
  Real Qin_agua1, Qin_oil1, Qout_agua1, Qout_oil1;
  Real Qin_agua2, Qin_oil2, Qout_agua2, Qout_oil2;

  // Válvulas controladas por PID
  Real valveOil1, valveAgua1;
  Real valveOil2, valveAgua2;

  // Controladores PID
  Modelica.Blocks.Continuous.PID pidOil1(k=1.0, Ti=300, Td=0.1);
  Modelica.Blocks.Continuous.PID pidAgua1(k=1.0, Ti=300, Td=0.1);
  Modelica.Blocks.Continuous.PID pidOil2(k=1.0, Ti=300, Td=0.1);
  Modelica.Blocks.Continuous.PID pidAgua2(k=1.0, Ti=300, Td=0.1);

equation
  // Balance dinámico separador 1
  der(V_oil1)  = Qin_oil1  - Qout_oil1;
  der(V_agua1) = Qin_agua1 - Qout_agua1;

  // Balance dinámico separador 2
  der(V_oil2)  = Qin_oil2  - Qout_oil2;
  der(V_agua2) = Qin_agua2 - Qout_agua2;

  // Set points
  pidOil1.u  = (0.54*V_sep - V_oil1);
  pidAgua1.u = (0.75*V_sep - (V_oil1+V_agua1));
  pidOil2.u  = (0.54*V_sep - V_oil2);
  pidAgua2.u = (0.75*V_sep - (V_oil2+V_agua2));

  // Válvulas
  valveOil1  = min(max(pidOil1.y, 0), 1);
  valveAgua1 = min(max(pidAgua1.y, 0), 1);
  valveOil2  = min(max(pidOil2.y, 0), 1);
  valveAgua2 = min(max(pidAgua2.y, 0), 1);

  // Salidas limitadas por volumen disponible
  Qout_oil1  = min(valveOil1  * (10*Qin_oil_base),  V_oil1);
  Qout_agua1 = min(valveAgua1 * (10*Qin_agua_base), V_agua1);
  Qout_oil2  = min(valveOil2  * (10*Qin_oil_base),  V_oil2);
  Qout_agua2 = min(valveAgua2 * (10*Qin_agua_base), V_agua2);

  // Entradas repartidas en paralelo
  Qin_oil1  = 0.5*Qin_oil_base;
  Qin_agua1 = 0.5*Qin_agua_base;
  Qin_oil2  = 0.5*Qin_oil_base;
  Qin_agua2 = 0.5*Qin_agua_base;

end SeparadoresTrifasicos_V46;
