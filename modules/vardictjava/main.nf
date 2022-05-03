process VARDICTJAVA {
    tag "$meta.id"
    label 'process_medium'

    conda (params.enable_conda ? "bioconda::vardict-java=1.8.3" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/vardict-java:1.8.3--hdfd78af_0':
        'quay.io/biocontainers/vardict-java:1.8.3--hdfd78af_0' }"

    input:
    tuple val(meta), path(bam), path(bai)
    path(regions_of_interest)
    tuple path(reference_fasta), path(reference_fai)

    output:
    tuple val(meta), path("*.vcf.gz"), emit: vcf
    path "versions.yml"              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    def VERSION = '1.8.3'

    """
    vardict-java \\
        $args \\
        -c 1 -S 2 -E 3 \\
        -b $bam \\
        -th $task.cpus \\
        -N $prefix \\
        -G $reference_fasta \\
        $regions_of_interest \\
        | teststrandbias.R \\
        | var2vcf_valid.pl \\
            $args2 \\
            -N $prefix \\
        | gzip -c > ${prefix}.vcf.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        vardict-java: \$VERSION
        var2vcf_valid.pl: \$(echo \$(var2vcf_valid.pl -h | sed -n 2p | awk '{ print \$2 }'))
    END_VERSIONS
    """
}
