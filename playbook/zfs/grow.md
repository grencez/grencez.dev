```shell
#v Limit size of dataset.
zfs set refquota=900G jankenpool/c/llama_model_data
#v Verify the change.
zfs get refquota jankenpool/c/llama_model_data

#v Unlimit refquota proerty on jankenpool/c dataset.
zfs inherit -S refquota jankenpool/c

#v See siblings of jankenpool/c/llama_model_data dataset.
zfs list -d 1 jankenpool/c
```
