within ;
model DosSeparadoresTrifasicosConDia
  inner Modelica.Fluid.System system;

  parameter Real V_sep   = 17.0;
  parameter Real P_sep   = 3.5e5;
  parameter Real Rgas    = 287;
  parameter Real Tgas    = 300;

  Real V_oil1(start=V_sep*0.45, min=0, max=V_sep);
  Real V_water1(start=V_sep*0.15, min=0, max=V_sep);
  Real P_gas1(start=3.0e5, min=1e5, max=3.5e5);

  Real V_oil2(start=V_sep*0.45, min=0, max=V_sep);
  Real V_water2(start=V_sep*0.15, min=0, max=V_sep);
  Real P_gas2(start=3.0e5, min=1e5, max=3.5e5);

  parameter Real Qin_oil_total   = 456/86400;
  parameter Real Qin_water_total = 2000/86400;
  parameter Real Qin_gas_total   = 5000/86400;

  Real Qin_oil1 = Qin_oil_total*0.6;
  Real Qin_oil2 = Qin_oil_total*0.4;
  Real Qin_water1 = Qin_water_total*0.6;
  Real Qin_water2 = Qin_water_total*0.4;
  Real Qin_gas1, Qin_gas2;

  Modelica.Blocks.Sources.Step perturbGas(height=Qin_gas_total*0.2, startTime=300);

  Real Qout_oil1, Qout_water1, Qout_gas1;
  Real Qout_oil2, Qout_water2, Qout_gas2;

  Real Qout_oil1_day, Qout_water1_day, Qout_gas1_day;
  Real Qout_oil2_day, Qout_water2_day, Qout_gas2_day;

  Modelica.Blocks.Continuous.PID pidOil1(k=1, Ti=60);
  Modelica.Blocks.Continuous.PID pidWater1(k=1, Ti=60);
  Modelica.Blocks.Continuous.PID pidGas1(k=0.2, Ti=40);

  Modelica.Blocks.Continuous.PID pidOil2(k=1, Ti=60);
  Modelica.Blocks.Continuous.PID pidWater2(k=1, Ti=60);
  Modelica.Blocks.Continuous.PID pidGas2(k=0.2, Ti=40);

  Modelica.Blocks.Sources.Constant spOil(k=V_sep*0.5);
  Modelica.Blocks.Sources.Constant spWater(k=V_sep*0.2);
  Modelica.Blocks.Sources.Constant spGas(k=P_sep);

  Real nivel_oil1(start=0);
  Real nivel_water1(start=0);
  Real nivel_oil2(start=0);
  Real nivel_water2(start=0);

  Real apertura_oil1(start=0);
  Real apertura_water1(start=0);
  Real apertura_gas1(start=0);

  Real apertura_oil2(start=0);
  Real apertura_water2(start=0);
  Real apertura_gas2(start=0);

equation
  Qin_gas1 = (Qin_gas_total*0.6) + perturbGas.y*0.6;
  Qin_gas2 = (Qin_gas_total*0.4) + perturbGas.y*0.4;

  der(V_oil1)   = Qin_oil1   - Qout_oil1;
  der(V_water1) = Qin_water1 - Qout_water1;
  der(P_gas1)   = (Rgas*Tgas/V_sep) * (Qin_gas1 - Qout_gas1);

  pidOil1.u   = spOil.k   - V_oil1;
  pidWater1.u = spWater.k - V_water1;
  pidGas1.u   = spGas.k   - P_gas1;

  Qout_oil1   = min(max(0, pidOil1.y   * 0.05), Qin_oil1);
  Qout_water1 = min(max(0, pidWater1.y * 0.05), Qin_water1);
  Qout_gas1   = min(max(0, pidGas1.y   * 0.05), Qin_gas1);

  Qout_oil1_day   = Qout_oil1   * 86400;
  Qout_water1_day = Qout_water1 * 86400;
  Qout_gas1_day   = Qout_gas1   * 86400;

  der(V_oil2)   = Qin_oil2   - Qout_oil2;
  der(V_water2) = Qin_water2 - Qout_water2;
  der(P_gas2)   = (Rgas*Tgas/V_sep) * (Qin_gas2 - Qout_gas2);

  pidOil2.u   = spOil.k   - V_oil2;
  pidWater2.u = spWater.k - V_water2;
  pidGas2.u   = spGas.k   - P_gas2;

  Qout_oil2   = min(max(0, pidOil2.y   * 0.05), Qin_oil2);
  Qout_water2 = min(max(0, pidWater2.y * 0.05), Qin_water2);
  Qout_gas2   = min(max(0, pidGas2.y   * 0.05), Qin_gas2);

  Qout_oil2_day   = Qout_oil2   * 86400;
  Qout_water2_day = Qout_water2 * 86400;
  Qout_gas2_day   = Qout_gas2   * 86400;

  nivel_oil1 = V_oil1 / V_sep * 100;
  nivel_water1 = V_water1 / V_sep * 100;
  nivel_oil2 = V_oil2 / V_sep * 100;
  nivel_water2 = V_water2 / V_sep * 100;

  apertura_oil1 = pidOil1.y * 100;
  apertura_water1 = pidWater1.y * 100;
  apertura_gas1 = pidGas1.y * 100;

  apertura_oil2 = pidOil2.y * 100;
  apertura_water2 = pidWater2.y * 100;
  apertura_gas2 = pidGas2.y * 100;
end DosSeparadoresTrifasicosConDia;
