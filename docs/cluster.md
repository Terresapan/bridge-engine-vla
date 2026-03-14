## Cluster Overview
You will have access to a dedicated Slurm cluster with 32 GPU compute nodes managed through 6 login nodes. All job scheduling is handled via Slurm.
- Storage: 61 TB shared Lustre filesystem — your home directory is on this shared storage, so your files are accessible from any login or compute node.
- GPUs: NVIDIA Driver 590.48.01 / CUDA 13.1 on every compute node.

### Getting Access
- Submit Your SSH Public Key: Send your public SSH key (e.g. ~/.ssh/id_ed25519.pub) to the organizers. If you don't have one yet:
ssh-keygen -t ed25519 -C "your_email@example.com"
cat ~/.ssh/id_ed25519.pub   # Send this to us

- Receive Your Credentials: You'll be assigned a username in the format user01 through user30. We'll confirm your username and which login node to use once your key is added.

- Connect via SSH
ssh <your-username>@<login-node-ip>

- Login Nodes:
us-west-a2-login-001 35.84.33.219
us-west-a2-login-002 44.230.162.249
us-west-a2-login-003 44.236.167.7  
us-west-a2-login-004 54.213.112.223
us-west-a2-login-005 184.34.82.180  
us-west-a2-login-006 184.33.101.123

- Tip: Any login node works — pick whichever you like, or spread out to avoid crowding a single node.