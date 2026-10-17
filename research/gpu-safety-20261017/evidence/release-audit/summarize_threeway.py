import pathlib,json
HERE=pathlib.Path(__file__).resolve().parent
TAGS=['v2.3.1','v2.3.2','v2.3.3']
results={tag:json.loads((HERE/(tag+'-archive-audit.json')).read_text()) for tag in TAGS}
def manifest(result):
    return {line.split('  ',1)[1]:line.split('  ',1)[0] for line in result['metadata']['pkgroot/SHA256SUMS']['value'].splitlines()}
sums={tag:manifest(result) for tag,result in results.items()}
summary={}
for a,b in [('v2.3.1','v2.3.2'),('v2.3.2','v2.3.3'),('v2.3.1','v2.3.3')]:
    summary[a+'..'+b]={
        'sha256sums_changed':{p:{a:sums[a].get(p),b:sums[b].get(p)} for p in sorted(sums[a].keys()|sums[b].keys()) if sums[a].get(p)!=sums[b].get(p)},
        'metadata_changed':[p for p in sorted(results[a]['metadata'].keys()|results[b]['metadata'].keys()) if results[a]['metadata'].get(p)!=results[b]['metadata'].get(p)],
        'driver_members_changed':[p for p in sorted(results[a]['drivers'].keys()|results[b]['drivers'].keys()) if results[a]['drivers'].get(p)!=results[b]['drivers'].get(p)]}
source=json.loads((HERE/'source-files-sha256.json').read_text())
summary['identity']={tag:result['metadata']['pkgroot/BASELINE-IDENTITY.json']['value'] for tag,result in results.items()}
summary['manifest_install_sha_matches_source']={tag:{source_tag:hashes['package/install.sh']==sums[tag].get('install.sh') for source_tag,hashes in source.items()} for tag in TAGS}
(HERE/'threeway-summary.json').write_text(json.dumps(summary,indent=2),encoding='utf-8')
print(json.dumps({k:v for k,v in summary.items() if k!='identity'},indent=2))
