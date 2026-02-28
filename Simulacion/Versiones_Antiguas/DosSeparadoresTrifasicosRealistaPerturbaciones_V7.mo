model DosSeparadoresTrifasicosRealistaPerturbaciones_V21

  inner Modelica.Fluid.System system;

  parameter Real V_sep   = 17.0 "Volumen del separador m3";
  parameter Real Qin_oil_base = 456/86400 "Caudal base de aceite m3/s";

  Real V_oil(start=0, min=0);
  Real Qin_oil, Qout_oil;
  Real valveOilIn, valveOilOut;

  // Controladores lentos
  Modelica.Blocks.Continuous.PID pidOilOut(k=0.007, Ti=8000);
  Modelica.Blocks.Continuous.PID pidOilIn(k=0.007, Ti=8000);

  // Setpoint normal oscilante (54% ±2%)
  Modelica.Blocks.Sources.Sine spOilOsc(
    amplitude=0.02*V_sep,
    f=1/3600,
    offset=V_sep*0.54);

  // Perturbaciones
  Modelica.Blocks.Sources.CombiTimeTable perturbOil(
    table=[0, Qin_oil_base;
           3600, Qin_oil_base;
           7200, Qin_oil_base*5.0;     // exceso → ~85-90%
           10800, Qin_oil_base;
           14400, Qin_oil_base*0.05;   // déficit → ~20%
           18000, Qin_oil_base],
    smoothness=Modelica.Blocks.Types.Smoothness.ConstantSegments);

  // Variables en porcentaje
  Real V_oil_pct, spOil_pct, valveOilIn_pct, valveOilOut_pct;

  // Setpoint dinámico
  Real spDynamic;

equation
  // Balance con protección
  der(V_oil) = noEvent(if V_oil > 0 then Qin_oil - Qout_oil else max(Qin_oil,0));

  // Setpoint dinámico: normal vs déficit
  if time >= 14400 and time < 18000 then
    spDynamic = 0.20*V_sep;   // 20% en déficit
  else
    spDynamic = spOilOsc.y;   // 54% ±2% normalmente
  end if;

  // PID de salida
  pidOilOut.u = (V_oil/V_sep*100) - (spDynamic/V_sep*100);
  valveOilOut = min(max(pidOilOut.y, 0), 1);

  // PID de entrada
  pidOilIn.u = (spDynamic/V_sep*100) - (V_oil/V_sep*100);
  valveOilIn = min(max(pidOilIn.y, 0), 1);

  // Entrada: cortada en déficit
  if time >= 14400 and time < 18000 then
    Qin_oil = 0;
  else
    Qin_oil = valveOilIn * perturbOil.y[1];
  end if;

  // Lógica de mesetas + salida agresiva
  if (time < 3600) then
    Qout_oil = Qin_oil; // meseta inicial
  elseif ((time >= 10800 and time < 14400) or time >= 18000)
       and abs(V_oil - spDynamic) < 0.02*V_sep then
    Qout_oil = Qin_oil; // mesetas intermedia y final
  else
    Qout_oil = max(0, valveOilOut * (V_oil/V_sep) * (Qin_oil_base)); // salida agresiva
  end if;

  // Variables en porcentaje
  V_oil_pct       = V_oil / V_sep * 100;
  spOil_pct       = spDynamic / V_sep * 100;
  valveOilIn_pct  = valveOilIn * 100;
  valveOilOut_pct = valveOilOut * 100;

end DosSeparadoresTrifasicosRealistaPerturbaciones_V21;
