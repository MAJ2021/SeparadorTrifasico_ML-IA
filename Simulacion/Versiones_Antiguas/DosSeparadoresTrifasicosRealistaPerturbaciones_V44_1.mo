model DosSeparadoresTrifasicosRealistaPerturbaciones_V44_1
  inner Modelica.Fluid.System system;

  parameter Real V_sep   = 17.0 "Volumen de cada separador m3";
  parameter Real tauRec = 700 "Constante de tiempo de recuperación";
  parameter Real Tdelay = 5 "Retardo dinámico de válvulas";

  // Caudales diarios convertidos a m3/s
  parameter Real Qin_water_total = 2000/86400;
  parameter Real Qin_oil_total   = 400/86400;
  parameter Real Qin_gas_total   = 4000/86400;

  // Reparto en paralelo (mitad a cada separador)
  parameter Real Qin_water_base = Qin_water_total/2;
  parameter Real Qin_oil_base   = Qin_oil_total/2;
  parameter Real Qin_gas_base   = Qin_gas_total/2;

  // Estados separador 1
  Real V_water1(start=0.75*V_sep), V_oil1(start=0.54*V_sep), P_gas1(start=3.5e5);
  Real Qin_water1, Qout_water1, Qin_oil1, Qout_oil1, Qin_gas1, Qout_gas1;
  Real valveWaterOut1, valveOilOut1, valveGasOut1;

  // Estados separador 2
  Real V_water2(start=0.75*V_sep), V_oil2(start=0.54*V_sep), P_gas2(start=3.5e5);
  Real Qin_water2, Qout_water2, Qin_oil2, Qout_oil2, Qin_gas2, Qout_gas2;
  Real valveWaterOut2, valveOilOut2, valveGasOut2;

  // PID controladores (completos con Td)
  Modelica.Blocks.Continuous.PID pidWaterOut1(k=0.01, Ti=5000, Td=0.1);
  Modelica.Blocks.Continuous.PID pidOilOut1(k=0.01, Ti=5000, Td=0.1);
  Modelica.Blocks.Continuous.PID pidGasOut1(k=0.01, Ti=2000, Td=0.1);

  Modelica.Blocks.Continuous.PID pidWaterOut2(k=0.01, Ti=5000, Td=0.1);
  Modelica.Blocks.Continuous.PID pidOilOut2(k=0.01, Ti=5000, Td=0.1);
  Modelica.Blocks.Continuous.PID pidGasOut2(k=0.01, Ti=2000, Td=0.1);

  // Retardos
  Modelica.Blocks.Continuous.FirstOrder delayWaterOut1(T=Tdelay);
  Modelica.Blocks.Continuous.FirstOrder delayOilOut1(T=Tdelay);
  Modelica.Blocks.Continuous.FirstOrder delayGasOut1(T=Tdelay);

  Modelica.Blocks.Continuous.FirstOrder delayWaterOut2(T=Tdelay);
  Modelica.Blocks.Continuous.FirstOrder delayOilOut2(T=Tdelay);
  Modelica.Blocks.Continuous.FirstOrder delayGasOut2(T=Tdelay);

  Real osc;

equation
  // Oscilaciones suaves
  osc = 0.02*sin(time/137) + 0.015*sin(time/271);

  // Balance separador 1
  der(V_water1) = Qin_water1 - Qout_water1 - (V_water1 - 0.75*V_sep)/tauRec;
  der(V_oil1)   = Qin_oil1   - Qout_oil1   - (V_oil1   - 0.54*V_sep)/tauRec;
  der(P_gas1)   = (Qin_gas1 - Qout_gas1)/V_sep - (P_gas1 - 3.5e5)/tauRec;

  // Balance separador 2
  der(V_water2) = Qin_water2 - Qout_water2 - (V_water2 - 0.75*V_sep)/tauRec;
  der(V_oil2)   = Qin_oil2   - Qout_oil2   - (V_oil2   - 0.54*V_sep)/tauRec;
  der(P_gas2)   = (Qin_gas2 - Qout_gas2)/V_sep - (P_gas2 - 3.5e5)/tauRec;

  // Entradas repartidas
  Qin_water1 = Qin_water_base;
  Qin_oil1   = Qin_oil_base;
  Qin_gas1   = Qin_gas_base;

  Qin_water2 = Qin_water_base;
  Qin_oil2   = Qin_oil_base;
  Qin_gas2   = Qin_gas_base;

  // PID con retardo separador 1
  pidWaterOut1.u = (V_water1 - 0.75*V_sep)/V_sep*100;
  delayWaterOut1.u = pidWaterOut1.y;
  valveWaterOut1 = min(max(delayWaterOut1.y,0),1);

  pidOilOut1.u = (V_oil1 - 0.54*V_sep)/V_sep*100;
  delayOilOut1.u = pidOilOut1.y;
  valveOilOut1 = min(max(delayOilOut1.y,0),1);

  pidGasOut1.u = (P_gas1 - 3.5e5)/1e5;
  delayGasOut1.u = pidGasOut1.y;
  valveGasOut1 = min(max(delayGasOut1.y,0),1);

  // PID con retardo separador 2
  pidWaterOut2.u = (V_water2 - 0.75*V_sep)/V_sep*100;
  delayWaterOut2.u = pidWaterOut2.y;
  valveWaterOut2 = min(max(delayWaterOut2.y,0),1);

  pidOilOut2.u = (V_oil2 - 0.54*V_sep)/V_sep*100;
  delayOilOut2.u = pidOilOut2.y;
  valveOilOut2 = min(max(delayOilOut2.y,0),1);

  pidGasOut2.u = (P_gas2 - 3.5e5)/1e5;
  delayGasOut2.u = pidGasOut2.y;
  valveGasOut2 = min(max(delayGasOut2.y,0),1);

  // Salidas definidas explícitamente separador 1
  Qout_water1 = valveWaterOut1 * Qin_water_base * (1 + osc);
  Qout_oil1   = valveOilOut1   * Qin_oil_base   * (1 + osc);
  Qout_gas1   = valveGasOut1   * Qin_gas_base   * (1 + osc);

  // Salidas definidas explícitamente separador 2
  Qout_water2 = valveWaterOut2 * Qin_water_base * (1 + osc);
  Qout_oil2   = valveOilOut2   * Qin_oil_base   * (1 + osc);
  Qout_gas2   = valveGasOut2   * Qin_gas_base   * (1 + osc);

end DosSeparadoresTrifasicosRealistaPerturbaciones_V44_1;
