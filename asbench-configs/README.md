# asbench Configuration Files

This directory contains pre-configured asbench workload files for the workshop.

## Available Configurations

| File | Description | Records | Workload |
|------|-------------|---------|----------|
| `insert-1m-records.yaml` | Initial data load | 1,000,000 | 100% inserts |
| `read-write-workload.yaml` | Mixed workload | Uses existing | 66% read, 34% update |

## Usage

### Load Initial Data
```bash
./insert-1m-records.sh
```

### Run Mixed Workload
```bash
./read-write-workload.sh
```

## More Information
See the [asbench documentation](https://docs.aerospike.com/tools/asbench) for all available options.

### Creating Custom Configurations
For customization and modifications the configuration YAML files for your own workloads, refer to the official documentation on asbench workload stages at [https://aerospike.com/docs/database/tools/asbench/#workload-stages](https://aerospike.com/docs/database/tools/asbench/#workload-stages) for detailed guidance on all available parameters and options.
