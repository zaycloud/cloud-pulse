#!/usr/bin/env python3
import time
import multiprocessing
import sys

def burn_cpu(duration):
    """
    Burn CPU for a specific duration in seconds.
    Performs heavy mathematical calculations to stress the processor.
    """
    end_time = time.time() + duration
    print(f"🔥 Process started. Burning CPU for {duration} seconds...")
    while time.time() < end_time:
        _ = 999999999 * 999999999

def main():
    # Default run time.
    duration = 60
    
    if len(sys.argv) > 1:
        try:
            duration = int(sys.argv[1])
        except ValueError:
            print("Usage: ./stress_cpu.py [duration_in_seconds]")
            sys.exit(1)

    cpu_count = multiprocessing.cpu_count()
    print(f"😈 STARING CHAOS DEMO on {cpu_count} CPU cores!")
    print(f"⏱️  Duration: {duration} seconds")
    
    processes = []

    # Start one process per CPU core.
    for _ in range(cpu_count):
        p = multiprocessing.Process(target=burn_cpu, args=(duration,))
        p.start()
        processes.append(p)

    # Wait for all processes to finish.
    for p in processes:
        p.join()

    print("✅ Chaos finished. System cooling down.")

if __name__ == "__main__":
    main()
