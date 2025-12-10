# asbench Configuration Files

This directory contains pre-configured asbench workload files for the workshop.

## Available Configurations

| File | Description | Records | Workload |
|------|-------------|---------|----------|
| `insert-1m-records.yaml` | Initial data load | 1,000,000 | 100% inserts |
| `read-write-workload.yaml` | Mixed workload | Uses existing | 80% read, 20% update |

## Usage

### Load Initial Data
```bash
asbench -c ~/asbench-configs/insert-1m-records.yaml
```

### Run Mixed Workload
```bash
asbench -c ~/asbench-configs/read-write-workload.yaml
```

### Override Host
```bash
asbench -c ~/asbench-configs/insert-1m-records.yaml --hosts aerospike-node-1:3000
```

## Creating Custom Configurations

Copy an existing file and modify as needed:

```bash
cp insert-1m-records.yaml my-custom-workload.yaml
nano my-custom-workload.yaml
```

### Key Parameters

- `keys`: Number of records
- `workload`: Type of workload (I=Insert, RU=Read/Update)
- `threads`: Concurrent operations
- `duration`: How long to run (seconds, 0=until data complete)
- `object-spec`: Field definitions

### Object Spec Data Types

| Type | Description | Example |
|------|-------------|---------|
| `I` | 64-bit Integer | `I` |
| `S:n` | String of n chars | `S:32` |
| `B:n` | Bytes (blob) of n bytes | `B:128` |
| `D` | Double (float) | `D` |

## More Information

See the [asbench documentation](https://docs.aerospike.com/tools/asbench) for all available options.

