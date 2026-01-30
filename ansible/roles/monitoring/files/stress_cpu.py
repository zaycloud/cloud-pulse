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
        # Heavy math operation to consume CPU cycles
        _ = 999999999 * 999999999

def main():
    # Default duration is 60 seconds if not specified
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
    
    # Launch one process per CPU core to ensure 100% usage
    # If we only used one process, we would only max out 1 of the 2 vCPUs (50% total load)
    for _ in range(cpu_count):
        p = multiprocessing.Process(target=burn_cpu, args=(duration,))
        p.start()
        processes.append(p)

    # Wait for all processes to finish
    for p in processes:
        p.join()

    print("✅ Chaos finished. System cooling down.")

if __name__ == "__main__":
    main()
