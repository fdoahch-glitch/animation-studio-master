#!/usr/bin/env python3
"""Supervisor determinista de avance: evita saltos y cierres sin evidencias."""
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
ROADMAP = ROOT / "project_data" / "roadmap_10_etapas.json"
VALID = {"pending", "in_progress", "partial", "done"}

def main():
    data = json.loads(ROADMAP.read_text(encoding="utf-8"))
    stages = data.get("stages", [])
    errors = []
    if len(stages) != 10:
        errors.append(f"Se esperaban 10 etapas; hay {len(stages)}.")
    ids = [s.get("id") for s in stages]
    if ids != list(range(1, 11)):
        errors.append("Las etapas deben estar numeradas secuencialmente del 1 al 10.")
    for s in stages:
        sid = s.get("id", "?")
        status = s.get("status")
        if status not in VALID:
            errors.append(f"Etapa {sid}: estado inválido: {status}.")
        if status == "done":
            for field in ("acceptance", "tests"):
                if not s.get(field):
                    errors.append(f"Etapa {sid}: no puede marcarse done sin {field}.")
            if not s.get("commit"):
                errors.append(f"Etapa {sid}: falta SHA del commit de cierre.")
    # Orden estricto: no iniciar una etapa posterior mientras una anterior no esté done.
    first_open = next((s for s in stages if s.get("status") != "done"), None)
    if first_open:
        later_active = [s["id"] for s in stages if s["id"] > first_open["id"] and s.get("status") == "in_progress"]
        if later_active:
            errors.append(f"Orden roto: etapas posteriores activas {later_active} mientras la {first_open['id']} no está done.")
    done_count = sum(1 for s in stages if s.get("status") == "done")
    next_pair = [s for s in stages if s.get("status") != "done"][:2]
    print(f"Supervisor: {done_count}/10 etapas cerradas.")
    print("Siguiente bloque: " + (" → ".join(f'{s["id"]}. {s["name"]}' for s in next_pair) if next_pair else "todas completadas"))
    for s in stages:
        print(f'[{s["status"].upper():11}] {s["id"]:02d} {s["name"]}')
    if errors:
        print("\nBLOQUEADO:")
        for e in errors:
            print("- " + e)
        return 1
    print("\nEstructura y secuencia correctas. Esto no sustituye las pruebas funcionales.")
    return 0

if __name__ == "__main__":
    sys.exit(main())
