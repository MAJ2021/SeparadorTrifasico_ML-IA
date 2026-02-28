model DosSeparadoresTrifasicosRealistaPerturbaciones_V38

  inner Modelica.Fluid.System system;

  parameter Real V_sep   = 17.0 "Volumen del separador m3";
  parameter Real Qin_oil_base = 456/86400 "Caudal base de aceite m3/s";

  Real V_oil(start=0.54*V_sep, min=0);
  Real Qin_oil, Qout_oil;
  Real valveOilIn, valveOilOut;

  // Controladores lentos
  Modelica.Blocks.Continuous.PID pidOilOut(k=0.005, Ti=10000);
  Modelica.Blocks.Continuous.PID pidOilIn(k=0.005, Ti=10000);

  // Perturbaciones
  Modelica.Blocks.Sources.CombiTimeTable perturbOil(
    table=[0, Qin_oil_base;
           3600, Qin_oil_base;
           7200, Qin_oil_base*5.0;     // exceso → ~90%
           10800, Qin_oil_base;
           14400, Qin_oil_base*0.05;   // déficit → ~20%
           18000, Qin_oil_base],
    smoothness=Modelica.Blocks.Types.Smoothness.ConstantSegments);

  // Variables en porcentaje
  Real V_oil_pct, spOil_pct, valveOilIn_pct, valveOilOut_pct;
  Real spDynamic;
  Real osc;

equation
  // Balance con protección
  der(V_oil) = noEvent(if V_oil > 0 then Qin_oil - Qout_oil else max(Qin_oil,0));

  // Setpoint dinámico según tramo
  if time >= 7200 and time < 10800 then
    spDynamic = 0.90*V_sep;   // exceso
  elseif time >= 10800 and time < 14400 then
    spDynamic = 0.54*V_sep;   // meseta intermedia
  elseif time >= 14400 and time < 18000 then
    spDynamic = 0.20*V_sep;   // déficit
  else
    spDynamic = 0.54*V_sep;   // meseta final
  end if;

  // PID de salida
  pidOilOut.u = (V_oil/V_sep*100) - (spDynamic/V_sep*100);
  valveOilOut = min(max(pidOilOut.y, 0), 1);

  // PID de entrada
  pidOilIn.u = (spDynamic/V_sep*100) - (V_oil/V_sep*100);
  valveOilIn = min(max(pidOilIn.y, 0), 1);

  // Entrada: cortada en déficit, reforzada en recuperación
  if time >= 14400 and time < 18000 then
    Qin_oil = 0;
  elseif time >= 18000 and time < 20000 then
    // Boost prolongado para recuperación
    Qin_oil = 2.0 * valveOilIn * perturbOil.y[1];
  else
    Qin_oil = valveOilIn * perturbOil.y[1];
  end if;

  // Oscilaciones pseudo-aleatorias
  osc = 0.05*sin(time/137) + 0.03*sin(time/271) + 0.02*sin(time/59);

  // Lógica de salida
  if (time >= 10800 and time < 14400) then
    // Meseta intermedia con oscilaciones naturales
    Qout_oil = Qin_oil * (1 + osc) + 0.3*valveOilOut*Qin_oil_base;
  elseif (time >= 14400 and time < 18000) then
    // Déficit: vaciado libre proporcional al nivel
    Qout_oil = (V_oil/V_sep) * Qin_oil_base;
  elseif (time >= 18000) then
    // Meseta final con recuperación + oscilaciones + PID
    Qout_oil = Qin_oil * (1 + osc) + 0.7*valveOilOut*Qin_oil_base;
  else
    // Exceso y normal: salida agresiva
    Qout_oil = max(0, valveOilOut * (V_oil/V_sep) * (2*Qin_oil_base));
  end if;

  // Variables en porcentaje
  V_oil_pct       = V_oil / V_sep * 100;
  spOil_pct       = spDynamic / V_sep * 100;
  valveOilIn_pct  = valveOilIn * 100;
  valveOilOut_pct = valveOilOut * 100;

end DosSeparadoresTrifasicosRealistaPerturbaciones_V38;
