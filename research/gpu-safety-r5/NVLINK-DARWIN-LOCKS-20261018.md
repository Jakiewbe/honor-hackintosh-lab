# NVLink Darwin ����˺�ѡ��2026-10-18��

Ŀ�꣺�������� NVRM �ؽ���ѡ�е��ĸ���ʵ�ڲ�ȱ�ڣ����ü� NVLink ����������ʹ�ÿ�׮���豸���м��� NO-GO��

## ����С�ͷ���

- ���룺ʵ��ֿ� main `63e489892fb8b1702d6883c24cceb6087c911b7c`��OGKM `e4a5faa2567f28c8eabe0ebb6422b6d0abcf37eb`��NullMoth `ac55984c473e746c2a8ebea7ba0913461aa7c393`�����޸� upstream��
- ������ʵ��[run 39116405484](https://github.com/Jakiewbe/honor-hackintosh-lab/actions/runs/39116405484) ��� 1280 �� C TU��5 �� shader ���������鵵�ͺ�ѡ���ӣ�ʣ�ĸ� NVLink �ڲ������� 471 ��Ŀ�굼��/ABI δ�����
- ��Լ��`nvlink_os.h:56�C60` ���� void acquire/release/free��`kernel-open/nvidia/nvlink_linux.c:564�C598` �ó�ֵ 1 �� Linux semaphore��`nvlink_lock.c` �� NV_LINUX �¿����������������Ƴ��ú�����������������
- ��ѡ·����`research/gpu-safety-r5/darwin/nvlink_locks.cpp` �������� TU��ͨ���̶� OGKM ��ʵ�ӿ�ͷУ�� C linkage ����������ʽ���벢�������������嵥��ԭ�� OGKM �鵵����ԭ����
- Darwin ���ݣ�[XNU xnu-11417.121.6 sync_sema.c](https://github.com/apple-oss-distributions/xnu/blob/xnu-11417.121.6/osfmk/kern/sync_sema.c)��`semaphore_wait()` �ɷ��� KERN_ABORTED��THREAD_INTERRUPTED����KERN_TERMINATED��THREAD_RESTART����`semaphore_signal()` ���� prepost ���壻`semaphore_destroy()` ���Ѵ��������á����Ѹòο�Դ�뵱��Ŀ��ϵͳ������ ABI ֤�ݡ�
- ʵ�֣��ں� semaphore ��ֵ 1��create ʧ���ͷŰ�װ�ڴ沢���� NULL��acquire �� KERN_ABORTED ���ԣ����� wait/signal/destroy �������Ч��� panic�����ٳɹ����ء�void �ӿ�û�пɻָ�����ͨ����panic �Ǳ���ѡ���������������ԣ����ܳ�Ϊ��ȫ�������ա�
- free �����ɵ��÷���֤�޳����ߡ��ȴ��ߺ��������á��˺�˲��ṩ�������١��ݹ顢�߳� ownership �������������ٲã�`nvlink_isLockOwner` �����ڱ����ĸ�ʵ�ʵ��룬�����Ӻ���ʵ�֡�
- ��֤α�㣺��ʵԴ��� CPU ����/������ͬ��ԭ������ȷ�ĸ�������ͬ run �������Ӻ��ĸ�������ʧ��û���µ��룻ʧ�ܻ�ȱʧ֤�ݾ��ܾ�ͨ����CPU ģ��ϵͳ�߽粻�� XNU ����֤�ݡ�
- ���ղ㼶�������� CPU ��ͬ �� Darwin ���� �� ����Դ���ѡ���ӡ����ء�GPU ��ʼ��/��Ⱦ/���ض��ؾ�δ��Ȩ��
- ���ˣ���˺������������ɿ�ͨ��������ͨ����ύ���������Ĺ�����ʷ���������豸��

## ��ǰ���

��ѡԴ�롢CPU ��ͬ��ԭ���Ž���׼����58 �� Python ���߼�鼰��ʷ����ع� 10/10��5/5��7/7 ����ʵͨ���������� C++ ��������CPU C++ ��ͬ���� Darwin ����/������δִ�У����������ĸ������ѹرա�CI ���� Xcode_16.4�����й��������ֽ� workflow_dispatch���ı��������ų������ơ���������ʵ������±��ڡ�
